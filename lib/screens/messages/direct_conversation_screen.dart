import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/colors.dart';

class DirectConversationScreen extends StatefulWidget {
  final String userId;
  const DirectConversationScreen({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _DirectConversationScreenState createState() => _DirectConversationScreenState();
}

class _DirectConversationScreenState extends State<DirectConversationScreen> {
  final Logger logger = Logger();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
  String? _recipientName = 'Support';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        setState(() {
          _error = 'Authentication token not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      
      // Use the direct API endpoint to fetch this specific conversation
      final url = '${AppConfig.apiBaseUrl}/messages/conversation/${widget.userId}';
      logger.i('Fetching messages from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      logger.i('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        logger.i('Received ${data.length} messages');
        
        final messages = data.map((json) => Message.fromJson(json)).toList();
        
        // Sort messages by sentAt timestamp
        messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Scroll to bottom of the chat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load messages: ${response.statusCode}';
          _isLoading = false;
        });
        logger.e('Error response: ${response.body}');
      }
    } catch (e) {
      logger.e('Error loading messages: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    try {
      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found. Please log in again.')),
        );
        return;
      }
      
      // Send message using API
      final url = '${AppConfig.apiBaseUrl}/messages/send';
      logger.i('Sending message to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipientId': widget.userId,
          'content': text,
        }),
      );
      
      logger.i('Send message response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear the text field
        _messageController.clear();
        
        // Reload messages to see the new message
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${response.statusCode}')),
        );
        logger.e('Error response: ${response.body}');
      }
    } catch (e) {
      logger.e('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;
    
    ScreenUtil.init(context, designSize: const Size(360, 690));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('No messages found'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16.r),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = message.senderId == currentUserId;
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8.r),
                                  child: Row(
                                    mainAxisAlignment: isMe 
                                        ? MainAxisAlignment.end 
                                        : MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.r, 
                                          vertical: 10.r,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe 
                                              ? AppColors.primaryColor 
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe 
                                              ? CrossAxisAlignment.end 
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.content,
                                              style: TextStyle(
                                                color: isMe ? Colors.white : Colors.black,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              DateFormatter.formatMessageTime(message.sentAt),
                                              style: TextStyle(
                                                color: isMe 
                                                    ? Colors.white.withOpacity(0.7) 
                                                    : Colors.black54,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.r, 
                        vertical: 8.r,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.r),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12.r),
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(24.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 