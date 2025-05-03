import 'dart:async';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/providers/message_provider.dart';
import 'package:HealthChain/screens/messages/components/message_bubble.dart';
import 'package:HealthChain/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:logger/logger.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Logger logger = Logger();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late MessageProvider _messageProvider;
  Timer? _refreshTimer;
  bool _isInitialLoadComplete = false; // Track initial load completion

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollToBottomIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages(context).then((_) {
        setState(() {
          _isInitialLoadComplete = true; // Mark initial load as complete
        });
      });
      logger.i('ChatScreen initialized for user ${widget.recipientName}');
      // Start auto-refresh timer
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          _loadMessages(context);
          logger.i('Auto-refreshing messages (silent)');
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider = Provider.of<MessageProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageProvider.leaveConversation();
    logger.i('ChatScreen disposed for user ${widget.recipientName}');
    super.dispose();
  }

  Future<void> _loadMessages(BuildContext context) async {
    try {
      await _messageProvider.loadConversation(widget.recipientId);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final currentUserId = authProvider.currentUser!.id;
        for (var message in _messageProvider.messages) {
          if (!message.isRead && message.recipientId == currentUserId) {
            await _messageProvider.markMessageAsRead(message.id);
          }
        }
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      logger.e('Error loading messages: $e');
    }
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageProvider.sendMessage(widget.recipientId, text);
    _messageController.clear();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomIfNeeded() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // At the top, no action needed
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MessageProvider>(
      builder: (context, authProvider, messageProvider, child) {
        if (authProvider.currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view this chat')),
          );
        }

        final currentUserId = authProvider.currentUser!.id;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.recipientName),
            backgroundColor: const Color(0xFF45B3CB),
          ),
          body: Column(
            children: [
              Expanded(
                child: messageProvider.isLoading && !_isInitialLoadComplete
                    ? const Center(child: CircularProgressIndicator())
                    : messageProvider.error != null
                        ? Center(child: Text('Error: ${messageProvider.error}'))
                        : messageProvider.messages.isEmpty
                            ? const Center(child: Text('No messages yet'))
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(10),
                                itemCount: messageProvider.messages.length,
                                itemBuilder: (context, index) {
                                  final message =
                                      messageProvider.messages[index];
                                  final isMe =
                                      message.senderId == currentUserId;
                                  return MessageBubble(
                                    message: message.content,
                                    isMe: isMe,
                                    time: DateFormatter.formatMessageTime(
                                        message.sentAt),
                                    isRead: message.isRead,
                                  );
                                },
                              ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                height: 70,
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: () => _sendMessage(context),
                      child: const Icon(Icons.send),
                      backgroundColor: const Color(0xFF45B3CB),
                      elevation: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
