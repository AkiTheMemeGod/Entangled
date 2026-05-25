import 'package:flutter/material.dart';
import 'app_colors.dart';

class Glassmorphism {
  static BoxDecoration getBaseDecoration(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final primary = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: primary.withAlpha(isDark ? 35 : 28), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 40 : 10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Plain solid card — no blur, works in both light and dark modes.
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
    final isDark = AppColors.isDarkMode(context);
    final primary = Theme.of(context).colorScheme.primary;
    final br = borderRadius ?? BorderRadius.circular(20);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: br,
        border: Border.all(
          color: primary.withAlpha(isDark ? 35 : 28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
