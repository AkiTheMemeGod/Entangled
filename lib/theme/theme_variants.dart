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
  final Color primaryDark;
  final Color secondaryDark;
  final Color primaryLight;
  final Color secondaryLight;
  final Color? bgDark;
  final Color? bgLight;

  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.primaryDark,
    required this.secondaryDark,
    required this.primaryLight,
    required this.secondaryLight,
    this.bgDark,
    this.bgLight,
  });

  static ThemePalette getPalette(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.monochrome:
        return const ThemePalette(
          primary: Colors.white,
          secondary: Color(0xFFE5E5E5),
          primaryDark: Colors.white,
          secondaryDark: Color(0xFF9CA3AF),
          primaryLight: Colors.black,
          secondaryLight: Color(0xFF4B5563),
          bgDark: Colors.black, // Pure OLED Black
          bgLight: Colors.white,
        );
      case AppThemeVariant.auroraCool:
        return const ThemePalette(
          primary: Color(0xFF2DD4BF), // Teal
          secondary: Color(0xFF60A5FA), // Blue
          primaryDark: Color(0xFF2DD4BF),
          secondaryDark: Color(0xFF60A5FA),
          primaryLight: Color(0xFF2DD4BF),
          secondaryLight: Color(0xFF60A5FA),
        );
      case AppThemeVariant.emberWarm:
        return const ThemePalette(
          primary: Color(0xFFFB923C), // Orange
          secondary: Color(0xFFF87171), // Red
          primaryDark: Color(0xFFFB923C),
          secondaryDark: Color(0xFFF87171),
          primaryLight: Color(0xFFFB923C),
          secondaryLight: Color(0xFFF87171),
        );
      case AppThemeVariant.deepOcean:
        return const ThemePalette(
          primary: Color(0xFF818CF8), // Indigo
          secondary: Color(0xFF22D3EE), // Cyan
          primaryDark: Color(0xFF818CF8),
          secondaryDark: Color(0xFF22D3EE),
          primaryLight: Color(0xFF818CF8),
          secondaryLight: Color(0xFF22D3EE),
        );
      case AppThemeVariant.obsidianBloom:
        return const ThemePalette(
          primary: Color(0xFF8B5CF6), // Radiant Violet
          secondary: Color(0xFFFB7185), // Electric Rose
          primaryDark: Color(0xFF8B5CF6),
          secondaryDark: Color(0xFFFB7185),
          primaryLight: Color(0xFF8B5CF6),
          secondaryLight: Color(0xFFFB7185),
        );
    }
  }
}
