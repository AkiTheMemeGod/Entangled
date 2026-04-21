class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String chatId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.chatId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientId: map['recipient_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      chatId: map['chat_id'] as String? ?? '',
      type: map['type'] as String? ?? 'new_message',
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
