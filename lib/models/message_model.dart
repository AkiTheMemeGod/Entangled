import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final String type; // "text" or "image"
  final Map<String, dynamic>? replyTo; // {id, text, sender}
  final String status; // "sent", "delivered", "read"
  final List<String> readBy;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.imageUrl,
    required this.type,
    this.replyTo,
    required this.status,
    required this.readBy,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      type: map['type'] ?? 'text',
      replyTo: map['replyTo'] != null ? Map<String, dynamic>.from(map['replyTo']) : null,
      status: map['status'] ?? 'sent',
      readBy: List<String>.from(map['readBy'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'type': type,
      if (replyTo != null) 'replyTo': replyTo,
      'status': status,
      'readBy': readBy,
      'timestamp': Timestamp.fromDate(timestamp), // use FieldValue.serverTimestamp() when sending
    };
  }
}
