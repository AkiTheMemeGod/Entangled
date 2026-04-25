import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Setup push-service background handler if available on this platform.
  try {
    await MessagingService.setupBackgroundHandling();
  } catch (e) {
    //print('MessagingService setup warning: $e');
  }

  runApp(const ProviderScope(child: EntangledApp()));
}

// TODO :
/* 
This is basically 
*/
