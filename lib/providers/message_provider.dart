import 'package:flutter/material.dart';
import 'package:HealthChain/models/conversation.dart';
import 'package:HealthChain/models/message.dart';
import 'package:HealthChain/services/api_service.dart';
import 'package:HealthChain/services/socket_service.dart';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:logger/logger.dart';

class MessageProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  String? _currentConversationUserId;
  bool _isLoading = false;
  String? _error;
  final Logger logger = Logger();

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MessageProvider(
      this._authProvider, this._apiService, this._webSocketService) {
    _webSocketService.onMessageReceived((message) {
      final newMessage = Message.fromJson(message);
      if (newMessage.senderId == _currentConversationUserId ||
          newMessage.recipientId == _authProvider.currentUser?.id) {
        if (!_messages.any((m) => m.id == newMessage.id)) {
          _messages.add(newMessage);
          notifyListeners();
        }
      }
      _updateConversations(newMessage);
    });
    _webSocketService.onMessageSent((message) {
      final sentMessage = Message.fromJson(message);
      if (sentMessage.senderId == _authProvider.currentUser?.id) {
        if (!_messages.any((m) => m.id == sentMessage.id)) {
          _messages.add(sentMessage);
          notifyListeners();
        }
      }
      _updateConversations(sentMessage);
    });
    _webSocketService.onMessageError((error) {
      logger.e('WebSocket message error: $error');
      _error = error;
      notifyListeners();
    });
  }

  void connectSocket() {
    logger.i('WebSocket connection requested');
  }

  void disconnectSocket() {
    _webSocketService.disconnect();
    logger.i('WebSocket disconnected');
  }

  void leaveConversation() {
    setCurrentConversationUserId(null);
    logger.i('Left conversation');
  }

  void setCurrentConversationUserId(String? userId) {
    _currentConversationUserId = userId;
    if (userId == null) {
      _messages = [];
    }
    notifyListeners();
  }

  Future<void> loadRecentConversations() async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _apiService.getConversations();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching conversations: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversation(String otherUserId) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _apiService.getMessages(otherUserId);
      _currentConversationUserId = otherUserId;
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching messages: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadConversationsFromJson(List<dynamic> conversationJson) {
    try {
      _conversations = conversationJson.map((json) {
        final data = json as Map<String, dynamic>;
        return Conversation(
          id: data['_id']?.toString() ?? '',
          recipientId: data['user']?['_id']?.toString() ?? '',
          recipientName: data['user']?['name']?.toString() ?? 'Unknown',
          recipientEmail: data['user']?['email']?.toString() ??
              '', // Fixed: Ensure non-null
          lastMessage: data['lastMessage'] != null
              ? Message(
                  id: data['lastMessage']['_id']?.toString() ?? '',
                  senderId: data['lastMessage']['senderId']?.toString() ?? '',
                  recipientId:
                      data['lastMessage']['recipientId']?.toString() ?? '',
                  conversationId:
                      data['lastMessage']['conversationId']?.toString() ?? '',
                  content: data['lastMessage']['content']?.toString() ?? '',
                  sentAt: DateTime.tryParse(
                          data['lastMessage']['sentAt']?.toString() ?? '') ??
                      DateTime.now(),
                  isRead: data['lastMessage']['isRead'] as bool? ?? false,
                  readAt: data['lastMessage']['readAt'] != null
                      ? DateTime.tryParse(
                          data['lastMessage']['readAt']?.toString() ?? '')
                      : null,
                )
              : null,
          lastMessageAt: DateTime.tryParse(
                  data['lastMessage']?['sentAt']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
      logger.i('Loaded ${_conversations.length} conversations from JSON');
    } catch (e) {
      logger.e('Error parsing conversations from JSON: $e');
      _conversations = [];
    }
    notifyListeners();
  }

  Future<void> sendMessage(String recipientId, String content) async {
    if (!_authProvider.isAuthenticated) return;
    try {
      final message = await _apiService.sendMessage(recipientId, content);
      _webSocketService.sendMessage(recipientId, content);
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        notifyListeners();
      }
      _updateConversations(message);
    } catch (e) {
      logger.e('Error sending message: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    if (!_authProvider.isAuthenticated) return;
    try {
      await _apiService.markMessageAsRead(messageId);
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = Message(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          recipientId: _messages[index].recipientId,
          conversationId: _messages[index].conversationId,
          content: _messages[index].content,
          sentAt: _messages[index].sentAt,
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error marking message as read: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateConversations(Message message) {
    final otherUserId = message.senderId == _authProvider.currentUser?.id
        ? message.recipientId
        : message.senderId;
    final index =
        _conversations.indexWhere((c) => c.recipientId == otherUserId);
    if (index != -1) {
      _conversations[index] = Conversation(
        id: _conversations[index].id,
        recipientId: _conversations[index].recipientId,
        recipientName: _conversations[index].recipientName,
        recipientEmail: _conversations[index].recipientEmail,
        lastMessage: message,
        lastMessageAt: message.sentAt,
      );
      notifyListeners();
    }
  }
}
