class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.lastSeen,
    required this.isOnline,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      lastSeen: _parseDateTime(map['lastSeen']),
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'],
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'lastSeen': lastSeen.toUtc().toIso8601String(),
      'isOnline': isOnline,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': createdAt.toUtc().toIso8601String(),
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

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastSeen,
    bool? isOnline,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
