import 'message.dart';

class Conversation {
  final String id;
  final String recipientId;
  final String recipientName;
  final String recipientEmail;
  final Message? lastMessage;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.recipientEmail,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      recipientId: json['user']['_id'] ?? '',
      recipientName: json['user']['name'] ?? '',
      recipientEmail: json['user']['email'] ?? '',
      lastMessage: json['lastMessage'] != null && json['lastMessage'].isNotEmpty
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: DateTime.parse(
          json['lastMessageAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
