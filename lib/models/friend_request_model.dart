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
      timestamp: _parseDateTime(map['timestamp']),
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
