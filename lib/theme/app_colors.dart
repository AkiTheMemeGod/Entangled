import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color secondary = Color(0xFF00D2FF);

  // Background
  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color bgLight = Color(0xFFF2F2F7);

  // Text
  static const Color textDarkInfo = Color(0xFFE0E0E0);
  static const Color textLightInfo = Color(0xFF333333);

  // Glassmorphism overlays
  static const Color glassWhite = Color(0xB3FFFFFF); // 70% white
  static const Color glassWhiteLight = Color(0x33FFFFFF); // 20% white
  static const Color glassDark = Color(0x0F000000); // 6% black
  static const Color glassDarkLight = Color(0x26000000); // 15% black
  static const Color glassBorderWhite = Color(0x26FFFFFF); // 15% white
  static const Color glassBorderDark = Color(0x1A000000); // 10% black

  // Status Colors
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);

  // Helper
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
