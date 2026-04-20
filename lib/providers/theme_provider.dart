import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_variants.dart';

class ThemeSettings {
  final ThemeMode mode;
  final AppThemeVariant variant;

  ThemeSettings({required this.mode, required this.variant});

  ThemeSettings copyWith({ThemeMode? mode, AppThemeVariant? variant}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
    );
  }
}

final themeSettingsProvider = NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
  return ThemeSettingsNotifier();
});

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const String _modeKey = 'theme_mode';
  static const String _variantKey = 'theme_variant';
  late SharedPreferences _prefs;

  @override
  ThemeSettings build() {
    _initPrefs();
    return ThemeSettings(
      mode: ThemeMode.system,
      variant: AppThemeVariant.obsidianBloom,
    );
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    
    final modeIndex = _prefs.getInt(_modeKey);
    final variantIndex = _prefs.getInt(_variantKey);

    state = ThemeSettings(
      mode: modeIndex != null ? ThemeMode.values[modeIndex] : ThemeMode.system,
      variant: variantIndex != null ? AppThemeVariant.values[variantIndex] : AppThemeVariant.obsidianBloom,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _prefs.setInt(_modeKey, mode.index);
  }

  void setThemeVariant(AppThemeVariant variant) {
    state = state.copyWith(variant: variant);
    _prefs.setInt(_variantKey, variant.index);
  }

  void toggleTheme() {
    final newMode = state.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }
}
