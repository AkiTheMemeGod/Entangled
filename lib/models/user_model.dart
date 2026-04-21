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
    final email = (map['email'] ?? '') as String;
    final displayName =
        (map['displayname'] ?? map['displayName'] ?? '') as String;
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName.isNotEmpty
          ? displayName
          : email.split('@').first,
      photoUrl: map['photourl'] ?? map['photoUrl'],
      lastSeen: _parseDateTime(map['lastseen'] ?? map['lastSeen']),
      isOnline: (map['isonline'] ?? map['isOnline'] ?? false) as bool,
      fcmToken: map['fcmtoken'] ?? map['fcmToken'],
      createdAt: _parseDateTime(map['createdat'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayname': displayName,
      if (photoUrl != null) 'photourl': photoUrl,
      'lastseen': lastSeen.toUtc().toIso8601String(),
      'isonline': isOnline,
      if (fcmToken != null) 'fcmtoken': fcmToken,
      'createdat': createdAt.toUtc().toIso8601String(),
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
