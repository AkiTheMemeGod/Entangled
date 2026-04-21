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
      senderId: map['senderid'] ?? map['senderId'] ?? '',
      senderName: map['sendername'] ?? map['senderName'] ?? '',
      text: map['text'],
      imageUrl: map['imageurl'] ?? map['imageUrl'],
      audioUrl: map['audiourl'] ?? map['audioUrl'],
      audioDurationMs: map['audiodurationms'] ?? map['audioDurationMs'],
      type: map['type'] ?? 'text',
      replyTo: (map['replyto'] ?? map['replyTo']) != null
          ? Map<String, dynamic>.from(map['replyto'] ?? map['replyTo'])
          : null,
      status: map['status'] ?? 'sent',
      readBy: List<String>.from(map['readby'] ?? map['readBy'] ?? []),
      deletedBy: List<String>.from(map['deletedby'] ?? map['deletedBy'] ?? []),
      isDeleted: map['isdeleted'] ?? map['isDeleted'] ?? false,
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderid': senderId,
      'sendername': senderName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageurl': imageUrl,
      if (audioUrl != null) 'audiourl': audioUrl,
      if (audioDurationMs != null) 'audiodurationms': audioDurationMs,
      'type': type,
      if (replyTo != null) 'replyto': replyTo,
      'status': status,
      'readby': readBy,
      'deletedby': deletedBy,
      'isdeleted': isDeleted,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      ).toLocal();
    }
    return DateTime.now();
  }
}
