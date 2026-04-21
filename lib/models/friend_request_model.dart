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
    final fromEmail = (map['fromemail'] ?? map['fromEmail'] ?? '') as String;
    final fromNameRaw = (map['fromname'] ?? map['fromName'] ?? '') as String;
    return FriendRequestModel(
      id: id,
      fromId: map['fromid'] ?? map['fromId'] ?? '',
      fromName: fromNameRaw.isNotEmpty
          ? fromNameRaw
          : fromEmail.split('@').first,
      fromEmail: fromEmail,
      fromPhoto: map['fromphoto'] ?? map['fromPhoto'],
      toId: map['toid'] ?? map['toId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Postgres folds unquoted mixed-case identifiers to lowercase.
      'fromid': fromId,
      'fromname': fromName,
      'fromemail': fromEmail,
      if (fromPhoto != null) 'fromphoto': fromPhoto,
      'toid': toId,
      'status': status,
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
