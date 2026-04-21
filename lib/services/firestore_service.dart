import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_model.dart';
import '../models/friend_request_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Users
  Future<void> createUser(UserModel user) async {
    await _supabase.from('users').upsert({'id': user.uid, ...user.toMap()});
  }

  Future<UserModel?> getUser(String uid) async {
    final rows = await _supabase.from('users').select().eq('id', uid).limit(1);
    if (rows.isEmpty) return null;

    final data = Map<String, dynamic>.from(rows.first as Map);
    return UserModel.fromMap(data, data['id'] as String? ?? uid);
  }

  Future<void> updateUserPresence(String uid, bool isOnline) async {
    await _supabase
        .from('users')
        .update({
          'isonline': isOnline,
          'lastseen': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', uid);
  }

  Future<void> updateFCMToken(String uid, String token) async {
    await _supabase.from('users').update({'fcmtoken': token}).eq('id', uid);
  }

  Future<void> updateUserPhotoUrl(String uid, String photoUrl) async {
    await _supabase.from('users').update({'photourl': photoUrl}).eq('id', uid);
  }

  Future<List<UserModel>> searchUsersByEmail(String email) async {
    final rows = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .limit(20);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((map) => UserModel.fromMap(map, map['id'] as String? ?? ''))
        .toList();
  }

  Stream<UserModel?> streamUser(String uid) {
    return _supabase.from('users').stream(primaryKey: ['id']).map((rows) {
      final filtered = rows.where((row) => row['id'] == uid).toList();
      if (filtered.isEmpty) return null;

      final data = Map<String, dynamic>.from(filtered.first);
      return UserModel.fromMap(data, data['id'] as String? ?? uid);
    });
  }

  // Friend Requests
  Future<void> sendFriendRequest(UserModel from, UserModel to) async {
    final requestId = '${from.uid}_${to.uid}';
    final request = FriendRequestModel(
      id: requestId,
      fromId: from.uid,
      fromName: from.displayName,
      fromEmail: from.email,
      fromPhoto: from.photoUrl,
      toId: to.uid,
      status: 'pending',
      timestamp: DateTime.now(),
    );

    await _supabase.from('friend_requests').upsert({
      'id': requestId,
      ...request.toMap(),
    });
  }

  Stream<List<FriendRequestModel>> streamIncomingRequests(String uid) {
    return _supabase.from('friend_requests').stream(primaryKey: ['id']).map((
      rows,
    ) {
      final requests = rows
          .map((row) => Map<String, dynamic>.from(row))
          .where(
            (map) =>
                (map['toid'] ?? map['toId']) == uid &&
                (map['status'] as String?) == 'pending',
          )
          .map(
            (map) =>
                FriendRequestModel.fromMap(map, map['id'] as String? ?? ''),
          )
          .toList();
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return requests;
    });
  }

  Future<String> getFriendshipStatus(String myUid, String otherUid) async {
    final outReq = await _supabase
        .from('friend_requests')
        .select('status')
        .eq('id', '${myUid}_$otherUid')
        .limit(1);
    if (outReq.isNotEmpty) {
      final status = (outReq.first as Map)['status'] as String? ?? 'pending';
      return status == 'accepted' ? 'friends' : 'pending_sent';
    }

    final inReq = await _supabase
        .from('friend_requests')
        .select('status')
        .eq('id', '${otherUid}_$myUid')
        .limit(1);
    if (inReq.isNotEmpty) {
      final status = (inReq.first as Map)['status'] as String? ?? 'pending';
      return status == 'accepted' ? 'friends' : 'pending_received';
    }

    return 'none';
  }

  Future<void> acceptFriendRequest(
    FriendRequestModel request,
    UserModel currentUser,
  ) async {
    await _supabase
        .from('friend_requests')
        .update({'status': 'accepted'})
        .eq('id', request.id);

    final otherUser = await getUser(request.fromId);
    if (otherUser != null) {
      await createOrGetChat(currentUser.uid, otherUser, currentUser);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _supabase.from('friend_requests').delete().eq('id', requestId);
  }

  // Chats
  Stream<List<ChatModel>> streamUserChats(String uid) {
    return _supabase.from('chats').stream(primaryKey: ['id']).map((rows) {
      final chats = rows
          .map((row) => Map<String, dynamic>.from(row))
          .where((map) {
            final participants = List<String>.from(
              map['participants'] ?? const <String>[],
            );
            return participants.contains(uid);
          })
          .map((map) => ChatModel.fromMap(map, map['id'] as String? ?? ''))
          .toList();
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return _supabase.from('chats').stream(primaryKey: ['id']).map((rows) {
      final filtered = rows.where((row) => row['id'] == chatId).toList();
      if (filtered.isEmpty) return null;

      final map = Map<String, dynamic>.from(filtered.first);
      return ChatModel.fromMap(map, map['id'] as String? ?? chatId);
    });
  }

  Future<String> createOrGetChat(
    String currentUid,
    UserModel otherUser,
    UserModel currentUser,
  ) async {
    final existingChats = await _supabase
        .from('chats')
        .select()
        .contains('participants', [currentUid])
        .eq('type', 'individual');

    for (final row in existingChats) {
      final doc = Map<String, dynamic>.from(row as Map);
      final participants = List<String>.from(doc['participants'] ?? const []);
      if (participants.contains(otherUser.uid) && participants.length == 2) {
        return doc['id'] as String;
      }
    }

    final chatId = const Uuid().v4();
    final chat = ChatModel(
      id: chatId,
      participants: [currentUid, otherUser.uid],
      participantNames: {
        currentUid: currentUser.displayName,
        otherUser.uid: otherUser.displayName,
      },
      participantPhotos: {
        if (currentUser.photoUrl != null) currentUid: currentUser.photoUrl!,
        if (otherUser.photoUrl != null) otherUser.uid: otherUser.photoUrl!,
      },
      lastMessage: 'Say hello!',
      lastMessageTime: DateTime.now(),
      lastMessageSenderId: '',
      type: 'individual',
      unreadCount: {currentUid: 0, otherUser.uid: 0},
      typingUsers: const [],
      createdAt: DateTime.now(),
    );

    await _supabase.from('chats').insert({'id': chatId, ...chat.toMap()});
    return chatId;
  }

  // Messages
  Stream<List<MessageModel>> streamMessages(String chatId, String currentUid) {
    return _supabase.from('messages').stream(primaryKey: ['id']).map((rows) {
      final messages = rows
          .map((row) => Map<String, dynamic>.from(row))
          .where((map) => (map['chatid'] ?? map['chatId']) == chatId)
          .map((map) => MessageModel.fromMap(map, map['id'] as String? ?? ''))
          .where((msg) => !msg.deletedBy.contains(currentUid))
          .toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages.take(50).toList();
    });
  }

  Future<void> deleteMessageForMe(
    String chatId,
    String messageId,
    String userId,
  ) async {
    final rows = await _supabase
        .from('messages')
        .select('deletedby')
        .eq('id', messageId)
        .eq('chatid', chatId)
        .limit(1);
    if (rows.isEmpty) return;

    final existing = List<String>.from(
      (rows.first as Map)['deletedby'] ?? const <String>[],
    );
    if (!existing.contains(userId)) {
      existing.add(userId);
    }
    await _supabase
        .from('messages')
        .update({'deletedby': existing})
        .eq('id', messageId)
        .eq('chatid', chatId);
  }

  Future<void> deleteMessageForAll(String chatId, String messageId) async {
    await _supabase
        .from('messages')
        .update({
          'text': null,
          'imageurl': null,
          'audiourl': null,
          'isdeleted': true,
          'type': 'text',
        })
        .eq('id', messageId)
        .eq('chatid', chatId);

    await _supabase
        .from('chats')
        .update({'lastmessage': 'This message was deleted'})
        .eq('id', chatId);
  }

  Future<void> sendMessage(
    String chatId,
    MessageModel message,
    String currentUid,
    String otherUid,
  ) async {
    await _supabase.from('messages').insert({
      'id': message.id,
      'chatid': chatId,
      ...message.toMap(),
    });

    final chatRows = await _supabase
        .from('chats')
        .select('unreadcount')
        .eq('id', chatId)
        .limit(1);

    final unread = <String, int>{};
    if (chatRows.isNotEmpty) {
      final unreadRaw = (chatRows.first as Map)['unreadcount'];
      if (unreadRaw is Map) {
        unread.addAll(
          unreadRaw.map(
            (key, value) => MapEntry('$key', (value as num).toInt()),
          ),
        );
      }
    }
    unread[otherUid] = (unread[otherUid] ?? 0) + 1;

    await _supabase
        .from('chats')
        .update({
          'lastmessage': message.type == 'image' ? 'Image' : message.text ?? '',
          'lastmessagetime': DateTime.now().toUtc().toIso8601String(),
          'lastmessagesenderid': currentUid,
          'unreadcount': unread,
        })
        .eq('id', chatId);
  }

  Future<void> markMessagesAsRead(
    String chatId,
    String uid,
    String otherUid,
  ) async {
    final chatRows = await _supabase
        .from('chats')
        .select('unreadcount')
        .eq('id', chatId)
        .limit(1);

    final unread = <String, int>{};
    if (chatRows.isNotEmpty) {
      final unreadRaw = (chatRows.first as Map)['unreadcount'];
      if (unreadRaw is Map) {
        unread.addAll(
          unreadRaw.map(
            (key, value) => MapEntry('$key', (value as num).toInt()),
          ),
        );
      }
    }
    unread[uid] = 0;

    await _supabase
        .from('chats')
        .update({'unreadcount': unread})
        .eq('id', chatId);

    final unreadMessages = await _supabase
        .from('messages')
        .select('id, readby, status')
        .eq('chatid', chatId)
        .eq('senderid', otherUid)
        .neq('status', 'read');

    for (final row in unreadMessages) {
      final msg = Map<String, dynamic>.from(row as Map);
      final readBy = List<String>.from(msg['readby'] ?? const <String>[]);
      if (!readBy.contains(uid)) {
        readBy.add(uid);
      }
      await _supabase
          .from('messages')
          .update({'status': 'read', 'readby': readBy})
          .eq('id', msg['id'] as String);
    }
  }

  Future<void> setTypingStatus(String chatId, String uid, bool isTyping) async {
    final rows = await _supabase
        .from('chats')
        .select('typingusers')
        .eq('id', chatId)
        .limit(1);
    final current = <String>[];
    if (rows.isNotEmpty) {
      current.addAll(
        List<String>.from(
          (rows.first as Map)['typingusers'] ?? const <String>[],
        ),
      );
    }

    if (isTyping) {
      if (!current.contains(uid)) {
        current.add(uid);
      }
    } else {
      current.remove(uid);
    }

    await _supabase
        .from('chats')
        .update({'typingusers': current})
        .eq('id', chatId);
  }

  Future<void> updateUserInAllChats(
    String uid, {
    String? photoUrl,
    String? displayName,
  }) async {
    final chats = await _supabase
        .from('chats')
        .select('id, participantnames, participantphotos')
        .contains('participants', [uid]);

    for (final row in chats) {
      final doc = Map<String, dynamic>.from(row as Map);
      final participantNames = Map<String, dynamic>.from(
        doc['participantnames'] ?? const <String, dynamic>{},
      );
      final participantPhotos = Map<String, dynamic>.from(
        doc['participantphotos'] ?? const <String, dynamic>{},
      );

      if (displayName != null) {
        participantNames[uid] = displayName;
      }
      if (photoUrl != null) {
        participantPhotos[uid] = photoUrl;
      }

      await _supabase
          .from('chats')
          .update({
            'participantnames': participantNames,
            'participantphotos': participantPhotos,
          })
          .eq('id', doc['id'] as String);
    }
  }
}
