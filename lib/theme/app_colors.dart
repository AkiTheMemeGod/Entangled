import 'package:flutter/material.dart';

class AppColors {
  // ── Cinnabar Palette (user-defined) ─────────────────────────────────────
  // Light mode surfaces
  static const Color lightBg = Color(0xFFFFFBF1); // warm ivory base
  static const Color lightSurface = Color(0xFFFFF2D0); // warm card
  static const Color lightAccent = Color(0xFFFFB2B2); // soft coral
  static const Color lightPrimary = Color(0xFFE36A6A); // cinnabar red

  // Dark mode accents
  static const Color darkPrimary = Color(0xFFEB4C4C); // vivid red
  static const Color darkSecondary = Color(0xFFFF7070); // lighter red
  static const Color darkAccent = Color(0xFFFFA6A6); // muted coral
  static const Color darkSurface = Color(
    0xFFFFEDC7,
  ); // warm sand (for tint refs)

  // Dark mode backgrounds (deep, not pure black — easier on eyes)
  static const Color darkBg = Color(0xFF1A0F0F); // very dark warm brown
  static const Color darkCard = Color(0xFF261414); // card surface

  // ── Glassmorphism ────────────────────────────────────────────────────────
  static const Color glassBase = Color(0x33FFFFFF);
  static const Color glassHeavy = Color(0x22000000);
  static const Color glassBorder = Color(0x18FFFFFF);
  static const Color glassBorderLight = Color(0x22000000);
  static const Color glassHighlight = Color(0x4DFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textMain = Color(0xFFFFF5F5); // near-white warm
  static const Color textDim = Color(0xFFCCA8A8); // muted warm
  static const Color textMuted = Color(0xFF9E7272); // dimmed
  static const Color textMainLight = Color(0xFF2C1010); // deep warm-brown
  static const Color textDimLight = Color(0xFF7A4040); // mid brown
  static const Color textMutedLight = Color(0xFFAA8080); // soft muted

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C77B);
  static const Color error = Color(0xFFEB4C4C);
  static const Color warning = Color(0xFFF59E0B);

  // ── Dynamic ──────────────────────────────────────────────────────────────
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  // ── Legacy aliases (keep so existing references compile) ─────────────────
  static const Color obsidianBase = darkBg;
  static const Color obsidianDeep = Color(0xFF110909);
  static const Color radiantViolet = darkPrimary;
  static const Color electricRose = darkSecondary;
  static const Color radiantIndigo = darkAccent;
  static const Color bgDark = darkBg;
  static const Color bgLight = lightBg;

  // ── Helper ────────────────────────────────────────────────────────────────
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
