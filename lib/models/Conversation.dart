import 'message.dart';

class Conversation {
  final String id;
  final String recipientId;
  final String recipientName;
  final String recipientEmail;
  final String? recipientPhoto;
  final Message? lastMessage;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.recipientEmail,
    this.recipientPhoto,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id']?.toString() ?? '',
      recipientId: json['user']?['_id']?.toString() ?? '',
      recipientName: json['user']?['name']?.toString() ?? 'Unknown',
      recipientEmail: json['user']?['email']?.toString() ?? '',
      recipientPhoto: json['user']?['photo']?.toString(),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      lastMessageAt:
          DateTime.tryParse(json['lastMessage']?['sentAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': {
        '_id': recipientId,
        'name': recipientName,
        'email': recipientEmail,
        'photo': recipientPhoto,
      },
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
    };
  }
}
