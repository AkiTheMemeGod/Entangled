import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class Glassmorphism {
  static BoxDecoration getBaseDecoration(BuildContext context) {
    bool isDark = AppColors.isDarkMode(context);
    return BoxDecoration(
      color: isDark ? AppColors.glassHeavy : AppColors.glassBase,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.glassBorder, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = AppColors.isDarkMode(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassHeavy : AppColors.glassBase,
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
