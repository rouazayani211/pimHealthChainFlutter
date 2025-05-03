import 'dart:async';
import 'package:HealthChain/providers/auth_provider.dart';
import 'package:HealthChain/providers/message_provider.dart';
import 'package:HealthChain/screens/messages/chat_screen.dart';
import 'package:HealthChain/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:logger/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  late TabController _tabController;
  late MessageProvider _messageProvider;
  Timer? _refreshTimer;
  bool _isInitialLoadComplete = false; // Track initial load completion

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider.connectSocket();
      _messageProvider.loadRecentConversations().then((_) {
        setState(() {
          _isInitialLoadComplete = true; // Mark initial load as complete
        });
      });
      logger.i('ConversationListScreen initialized');
      // Start auto-refresh timer
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          _messageProvider.loadRecentConversations();
          logger.i('Auto-refreshing conversations (silent)');
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
    _tabController.dispose();
    _messageProvider.disconnectSocket();
    logger.i('ConversationListScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Group'),
            Tab(text: 'Private'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList(),
          const Center(child: Text('Group conversations coming soon')),
          _buildConversationList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          logger.i('New chat FAB pressed');
          // TODO: Implement new chat functionality
        },
        child: const Icon(Icons.chat),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildConversationList() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        // Show loading indicator only during initial load
        if (messageProvider.isLoading && !_isInitialLoadComplete) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messageProvider.error != null) {
          logger.e('ConversationListScreen error: ${messageProvider.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${messageProvider.error}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    messageProvider.loadRecentConversations();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (messageProvider.conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => messageProvider.loadRecentConversations(),
          child: ListView.builder(
            itemCount: messageProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = messageProvider.conversations[index];
              final lastMessage = conversation.lastMessage;
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.currentUser == null) {
                return const SizedBox.shrink();
              }

              final isUnread = lastMessage != null &&
                  !lastMessage.isRead &&
                  lastMessage.recipientId == authProvider.currentUser!.id;

              final userName = conversation.recipientName;
              final userId = conversation.recipientId;
              final userPhoto = (authProvider.currentUser != null &&
                      authProvider.currentUser!.photo != null)
                  ? authProvider.currentUser!.photo
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: userPhoto != null && userPhoto.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(userPhoto),
                        )
                      : CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage?.content ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black : Colors.grey,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatMessageTime(
                            conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientId: userId,
                          recipientName: userName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
