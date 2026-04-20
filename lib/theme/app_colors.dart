import 'package:flutter/material.dart';

class AppColors {
  // Fixed Base Colors
  static const Color obsidianBase = Color(0xFF0A0A12);
  static const Color obsidianDeep = Color(0xFF050508);
  
  // Backgrounds
  static const Color bgDark = obsidianBase;
  static const Color bgLight = Color(0xFFF8F9FA);

  // Glassmorphism System
  static const Color glassBase = Color(0x33FFFFFF);
  static const Color glassHeavy = Color(0x66000000);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x4DFFFFFF);

  // Text Colors
  static const Color textMain = Color(0xFFF9FAFB);
  static const Color textDim = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textMainLight = Color(0xFF111827);
  static const Color textDimLight = Color(0xFF4B5563);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Dynamic Accents
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;

  // Legacy Compatibility (defaults to Obsidian Bloom palette)
  static const Color radiantViolet = Color(0xFF8B5CF6);
  static const Color electricRose = Color(0xFFFB7185);
  static const Color radiantIndigo = Color(0xFF6366F1);

  // Helper
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
