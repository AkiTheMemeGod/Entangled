import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/friend_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateUserPresence(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFCMToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  Future<List<UserModel>> searchUsersByEmail(String email) async {
    QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
        
    return result.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Friend Requests
  Future<void> sendFriendRequest(UserModel from, UserModel to) async {
    final requestId = '${from.uid}_${to.uid}';
    final doc = _firestore.collection('friend_requests').doc(requestId);
    
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

    await doc.set(request.toMap());
  }

  Stream<List<FriendRequestModel>> streamIncomingRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('toId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> getFriendshipStatus(String myUid, String otherUid) async {
    // Check if friends
    final outReq = await _firestore.collection('friend_requests').doc('${myUid}_${otherUid}').get();
    if (outReq.exists) {
      return outReq.get('status') == 'accepted' ? 'friends' : 'pending_sent';
    }

    final inReq = await _firestore.collection('friend_requests').doc('${otherUid}_${myUid}').get();
    if (inReq.exists) {
      return inReq.get('status') == 'accepted' ? 'friends' : 'pending_received';
    }

    return 'none';
  }

  Future<void> acceptFriendRequest(FriendRequestModel request, UserModel currentUser) async {
    // 1. Update request status
    await _firestore.collection('friend_requests').doc(request.id).update({
      'status': 'accepted',
    });

    // 2. Create the chat automatically
    final otherUser = await getUser(request.fromId);
    if (otherUser != null) {
      await createOrGetChat(currentUser.uid, otherUser, currentUser);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // Chats
  Stream<List<ChatModel>> streamUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid needing a Firestore composite index
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  Future<String> createOrGetChat(String currentUid, UserModel otherUser, UserModel currentUser) async {
    QuerySnapshot existingChats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .get();

    for (var doc in existingChats.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUser.uid) && participants.length == 2 && doc['type'] == 'individual') {
        return doc.id;
      }
    }

    // Create new chat
    DocumentReference newChat = _firestore.collection('chats').doc();
    ChatModel chat = ChatModel(
      id: newChat.id,
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
      typingUsers: [],
      createdAt: DateTime.now(),
    );

    await newChat.set(chat.toMap());
    return newChat.id;
  }

  // Messages
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(String chatId, MessageModel message, String currentUid, String otherUid) async {
    DocumentReference msgDoc = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    await msgDoc.set(message.toMap());

    // Update chat details
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.type == 'image' ? '📷 Image' : message.text ?? '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUid,
      'unreadCount.$otherUid': FieldValue.increment(1),
    });
  }

  Future<void> markMessagesAsRead(String chatId, String uid, String otherUid) async {
    // Reset unread count on the chat document
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$uid': 0,
    });

    // Get all messages from the other user, then filter client-side
    // to avoid needing a Firestore composite index
    final otherUserMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: otherUid)
        .get();

    final unread = otherUserMessages.docs.where((doc) {
      final data = doc.data();
      return data['status'] != 'read';
    }).toList();

    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in unread) {
      batch.update(doc.reference, {
        'status': 'read',
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }

  Future<void> setTypingStatus(String chatId, String uid, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers': isTyping 
          ? FieldValue.arrayUnion([uid]) 
          : FieldValue.arrayRemove([uid]),
    });
  }
}

