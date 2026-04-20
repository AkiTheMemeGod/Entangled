import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class MessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> init(String uid) async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestoreService.updateFCMToken(uid, token);
      }

      // Handle token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _firestoreService.updateFCMToken(uid, newToken);
      });
    }
  }

  static Future<void> setupBackgroundHandling() async {
    // You must set this outside of widget tree
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // We'll leave it simple for now.
}
