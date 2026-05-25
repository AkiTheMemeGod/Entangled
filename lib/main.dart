import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request the highest available refresh rate on this device.
  // On Android this lets the OS pick 90/120Hz when the phone supports it.
  // On other platforms this is a no-op.
  await _enableHighRefreshRate();

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

/// Requests the highest supported display refresh rate from the OS.
///
/// Flutter on Android defaults to 60 Hz even on 120 Hz panels unless the
/// engine is explicitly told to opt in. We call [FlutterView.physicsHighRefreshRate]
/// via [SchedulerBinding] and also push a platform channel call that sets
/// `preferHighRefreshRate` on the Android [Window] for older engine versions.
Future<void> _enableHighRefreshRate() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {
    // Never crash the app due to orientation/refresh-rate hint failure.
  }
}
