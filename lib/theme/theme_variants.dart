import 'package:flutter/material.dart';

enum AppThemeVariant {
  obsidianBloom,
  monochrome,
  auroraCool,
  emberWarm,
  deepOcean,
}

class ThemePalette {
  final Color primary;
  final Color secondary;
  final Color? bgDark;
  final Color? bgLight;

  const ThemePalette({
    required this.primary,
    required this.secondary,
    this.bgDark,
    this.bgLight,
  });

  static ThemePalette getPalette(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.monochrome:
        return const ThemePalette(
          primary: Colors.white,
          secondary: Color(0xFFE5E5E5),
          bgDark: Colors.black,
          bgLight: Colors.white,
        );
      case AppThemeVariant.auroraCool:
        return const ThemePalette(
          primary: Color(0xFF2DD4BF), // Teal
          secondary: Color(0xFF60A5FA), // Blue
        );
      case AppThemeVariant.emberWarm:
        return const ThemePalette(
          primary: Color(0xFFFB923C), // Orange
          secondary: Color(0xFFF87171), // Red
        );
      case AppThemeVariant.deepOcean:
        return const ThemePalette(
          primary: Color(0xFF818CF8), // Indigo
          secondary: Color(0xFF22D3EE), // Cyan
        );
      case AppThemeVariant.obsidianBloom:
      default:
        return const ThemePalette(
          primary: Color(0xFF8B5CF6), // Radiant Violet
          secondary: Color(0xFFFB7185), // Electric Rose
        );
    }
  }
}
