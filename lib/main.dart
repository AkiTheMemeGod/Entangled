import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/firebase_options.dart';
import 'services/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup FCM background handler
  try {
    await MessagingService.setupBackgroundHandling();
  } catch (e) {
    // Firebase Messaging may not be available on all platforms
    print('MessagingService setup warning: $e');
  }

  runApp(const ProviderScope(child: EntangledApp()));
}
