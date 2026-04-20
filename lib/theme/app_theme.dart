import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

import 'theme_variants.dart';

class AppTheme {
  static ThemeData getLightTheme(ThemePalette palette) {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: Colors.white,
        onSurface: AppColors.textMainLight,
        onSurfaceVariant: AppColors.textDimLight,
      ),
      scaffoldBackgroundColor: palette.bgLight ?? AppColors.bgLight,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.textMainLight,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.outfit(color: AppColors.textMainLight),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textDimLight),
        bodySmall: GoogleFonts.outfit(color: AppColors.textMutedLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textMainLight,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMainLight),
      ),
    );
  }

  static ThemeData getDarkTheme(ThemePalette palette) {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.bgDark ?? AppColors.obsidianBase,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: const Color(0xFF161625),
        onSurface: AppColors.textMain,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.textMain,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.outfit(color: AppColors.textMain),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textDim),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textMain,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: palette.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.transparent, // Will be set in widget if needed
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
