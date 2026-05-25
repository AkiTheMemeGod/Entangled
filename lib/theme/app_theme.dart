import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_variants.dart';

class AppTheme {
  static ThemeData getLightTheme(ThemePalette palette) {
    final primary = palette.primaryLight;
    final secondary = palette.secondaryLight;
    final bg = palette.bgLight ?? AppColors.lightBg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: AppColors.textMainLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.textMainLight,
        onSurfaceVariant: AppColors.textDimLight,
        outline: AppColors.glassBorderLight,
        error: AppColors.error,
      ),
      textTheme: _textTheme(
        AppColors.textMainLight,
        AppColors.textDimLight,
        AppColors.textMutedLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textMainLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMainLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withAlpha(40), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withAlpha(60)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withAlpha(40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.textMutedLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: primary.withAlpha(30),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withAlpha(180)
              : AppColors.textMutedLight.withAlpha(60),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(ThemePalette palette) {
    final primary = palette.primaryDark;
    final secondary = palette.secondaryDark;
    final bg = palette.bgDark ?? AppColors.darkBg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: AppColors.darkCard,
        onSurface: AppColors.textMain,
        onSurfaceVariant: AppColors.textDim,
        outline: AppColors.glassBorder,
        error: AppColors.error,
      ),
      textTheme: _textTheme(
        AppColors.textMain,
        AppColors.textDim,
        AppColors.textMuted,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textMain,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withAlpha(35), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withAlpha(35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: primary.withAlpha(25),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : AppColors.textDim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withAlpha(160)
              : AppColors.textMuted.withAlpha(60),
        ),
      ),
    );
  }

  static TextTheme _textTheme(
    Color main,
    Color dim,
    Color muted,
  ) => GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(color: main, fontWeight: FontWeight.w800),
    headlineLarge: GoogleFonts.outfit(color: main, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.outfit(
      color: main,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.outfit(color: main, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.outfit(color: main, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.outfit(color: main),
    bodyMedium: GoogleFonts.outfit(color: dim),
    bodySmall: GoogleFonts.outfit(color: muted),
    labelLarge: GoogleFonts.outfit(color: main, fontWeight: FontWeight.w600),
    labelSmall: GoogleFonts.outfit(color: muted, letterSpacing: 0.8),
  );
}
