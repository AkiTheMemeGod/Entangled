import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String fromId;
  final String fromName;
  final String fromEmail;
  final String? fromPhoto;
  final String toId;
  final String status; // 'pending', 'accepted'
  final DateTime timestamp;

  FriendRequestModel({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.fromEmail,
    this.fromPhoto,
    required this.toId,
    required this.status,
    required this.timestamp,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return FriendRequestModel(
      id: id,
      fromId: map['fromId'] ?? '',
      fromName: map['fromName'] ?? '',
      fromEmail: map['fromEmail'] ?? '',
      fromPhoto: map['fromPhoto'],
      toId: map['toId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromId': fromId,
      'fromName': fromName,
      'fromEmail': fromEmail,
      if (fromPhoto != null) 'fromPhoto': fromPhoto,
      'toId': toId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
