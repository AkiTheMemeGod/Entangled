import 'firestore_service.dart';

class MessagingService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> init(String uid) async {
    // Pure Supabase mode: we keep this call for compatibility with
    // existing startup flow, but no external push token is registered.
    await _firestoreService.updateFCMToken(uid, 'supabase_realtime_only');
  }

  Future<void> clearToken(String uid) async {
    await _firestoreService.updateFCMToken(uid, '');
  }

  static Future<void> setupBackgroundHandling() async {}
}
