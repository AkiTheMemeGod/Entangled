import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

import 'theme/theme_variants.dart';

class EntangledApp extends ConsumerWidget {
  const EntangledApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final palette = ThemePalette.getPalette(settings.variant);

    return MaterialApp(
      title: 'Entangled',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(palette),
      darkTheme: AppTheme.getDarkTheme(palette),
      themeMode: settings.mode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
