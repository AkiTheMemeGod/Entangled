import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleHelper {
  static TextStyle outfitStyle({
    required double fontSize,
    required double fontSizeMultiplier,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize * fontSizeMultiplier,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }
}
