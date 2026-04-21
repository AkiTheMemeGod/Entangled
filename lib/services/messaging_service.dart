import 'firestore_service.dart';

class MessagingService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> init(String uid) async {
    // Push notifications are not wired to Supabase in this migration.
    // Keep a known placeholder token so schema expectations remain stable.
    await _firestoreService.updateFCMToken(uid, 'push_not_configured');
  }

  static Future<void> setupBackgroundHandling() async {}
}
