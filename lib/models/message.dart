class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String conversationId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.conversationId,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      conversationId: json['conversationId'],
      content: json['content'],
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'],
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'conversationId': conversationId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }
}
