import 'dart:async';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/providers/message_provider.dart';
import 'package:HealthChain/screens/messages/components/message_bubble.dart';
import 'package:HealthChain/services/socket_service.dart';
import 'package:HealthChain/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../call/call_screen.dart';

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
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollToBottomIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages(context).then((_) {
        setState(() {
          _isInitialLoadComplete = true;
        });
      });
      logger.i('ChatScreen initialized for user ${widget.recipientName}');
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

  Future<bool> _requestCallPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.camera, // Added for video calls
    ].request();

    bool allGranted = true;
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      logger.w('Microphone permission denied');
      allGranted = false;
    }
    if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      logger.w('Bluetooth connect permission denied');
      allGranted = false;
    }
    if (statuses[Permission.camera] != PermissionStatus.granted &&
        widget.recipientName.contains('video')) {
      logger.w('Camera permission denied');
      allGranted = false;
    }

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please grant microphone, camera, and Bluetooth permissions to make a call')),
      );
    }
    return allGranted;
  }

  Future<void> _startAudioCall(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a call')),
      );
      return;
    }

    // Request permissions before initiating the call
    bool permissionsGranted = await _requestCallPermissions();
    if (!permissionsGranted) return;

    final currentUserId = authProvider.currentUser!.id;
    final currentUserName = authProvider.currentUser!.name ??
        'Unknown'; // Ensure caller name is fetched
    final callId =
        '${currentUserId}_${widget.recipientId}_${DateTime.now().millisecondsSinceEpoch}';
    logger.i(
        'Initiating audio call with callID: $callId to ${widget.recipientName}');
    socketService.emitCallEvent('start_call', {
      'callId': callId,
      'callerId': currentUserId,
      'callerName': currentUserName,
      'recipientId': widget.recipientId,
      'recipientName': widget.recipientName,
      'callType': 'audio',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Call ID: $callId (waiting for ${widget.recipientName})')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          callID: callId,
          userID: currentUserId,
          userName: widget.recipientName,
          isCaller: true,
          isVideoCall: false,
        ),
      ),
    );
  }

  Future<void> _startVideoCall(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socketService = Provider.of<WebSocketService>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a call')),
      );
      return;
    }

    // Request permissions before initiating the call
    bool permissionsGranted = await _requestCallPermissions();
    if (!permissionsGranted) return;

    final currentUserId = authProvider.currentUser!.id;
    final currentUserName = authProvider.currentUser!.name ??
        'Unknown'; // Ensure caller name is fetched
    final callId =
        '${currentUserId}_${widget.recipientId}_${DateTime.now().millisecondsSinceEpoch}';
    logger.i(
        'Initiating video call with callID: $callId to ${widget.recipientName}');
    socketService.emitCallEvent('start_call', {
      'callId': callId,
      'callerId': currentUserId,
      'callerName': currentUserName,
      'recipientId': widget.recipientId,
      'recipientName': widget.recipientName,
      'callType': 'video',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Call ID: $callId (waiting for ${widget.recipientName})')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          callID: callId,
          userID: currentUserId,
          userName: widget.recipientName,
          isCaller: true,
          isVideoCall: true,
        ),
      ),
    );
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(widget.recipientName),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: () => _startVideoCall(context),
              ),
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => _startAudioCall(context),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  logger.i('More options opened for ${widget.recipientName}');
                },
              ),
            ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type message ...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _sendMessage(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45B3CB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      child: const Text(
                        'SEND',
                        style: TextStyle(color: Colors.white),
                      ),
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
