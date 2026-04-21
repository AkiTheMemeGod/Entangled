class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationMs;
  final String type; // "text", "image", or "audio"
  final Map<String, dynamic>? replyTo; // {id, text, sender}
  final String status; // "sent", "delivered", "read"
  final List<String> readBy;
  final List<String> deletedBy;
  final bool isDeleted;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.audioDurationMs,
    required this.type,
    this.replyTo,
    required this.status,
    required this.readBy,
    this.deletedBy = const [],
    this.isDeleted = false,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      audioDurationMs: map['audioDurationMs'],
      type: map['type'] ?? 'text',
      replyTo: map['replyTo'] != null
          ? Map<String, dynamic>.from(map['replyTo'])
          : null,
      status: map['status'] ?? 'sent',
      readBy: List<String>.from(map['readBy'] ?? []),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (audioDurationMs != null) 'audioDurationMs': audioDurationMs,
      'type': type,
      if (replyTo != null) 'replyTo': replyTo,
      'status': status,
      'readBy': readBy,
      'deletedBy': deletedBy,
      'isDeleted': isDeleted,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String)
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      ).toLocal();
    }
    return DateTime.now();
  }
}
