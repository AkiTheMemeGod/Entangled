import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeSettings {
  final double multiplier;

  FontSizeSettings({required this.multiplier});

  FontSizeSettings copyWith({double? multiplier}) {
    return FontSizeSettings(
      multiplier: multiplier ?? this.multiplier,
    );
  }
}

final fontSizeProvider =
    NotifierProvider<FontSizeNotifier, FontSizeSettings>(() {
      return FontSizeNotifier();
    });

class FontSizeNotifier extends Notifier<FontSizeSettings> {
  static const String _multiplierKey = 'font_size_multiplier';
  late SharedPreferences _prefs;

  @override
  FontSizeSettings build() {
    _initPrefs();
    return FontSizeSettings(multiplier: 1.0);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final multiplier = _prefs.getDouble(_multiplierKey);
    if (multiplier != null) {
      state = FontSizeSettings(multiplier: multiplier);
    }
  }

  void setFontSizeMultiplier(double multiplier) {
    final clampedMultiplier = multiplier.clamp(0.8, 1.5);
    state = state.copyWith(multiplier: clampedMultiplier);
    _prefs.setDouble(_multiplierKey, clampedMultiplier);
  }
}
