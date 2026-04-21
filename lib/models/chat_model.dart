class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final String type; // "individual" or "group"
  final Map<String, int> unreadCount;
  final List<String> typingUsers;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.type,
    required this.unreadCount,
    required this.typingUsers,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos: Map<String, String>.from(
        map['participantPhotos'] ?? {},
      ),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: _parseDateTime(map['lastMessageTime']),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      type: map['type'] ?? 'individual',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      typingUsers: List<String>.from(map['typingUsers'] ?? []),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toUtc().toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'type': type,
      'unreadCount': unreadCount,
      'typingUsers': typingUsers,
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
}
