import 'package:flutter/material.dart';

/// Plain static background — no animation, no GPU blur.
/// Reads the scaffold colour from the theme so light/dark modes work.
class AnimatedGradientBg extends StatelessWidget {
  final Widget child;
  final Color? baseColor;

  const AnimatedGradientBg({
    super.key,
    required this.child,
    this.baseColor,
    // ignore: avoid_unused_constructor_parameters
    double intensity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final bg = baseColor ?? Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(color: bg, child: child);
  }
}

/// Plain solid surface card — no blur, no BackdropFilter.
class FrostSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? tint;

  const FrostSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tint,
    // ignored — kept for call-site compat
    double blur = 18,
    bool gradientBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = tint ?? theme.colorScheme.surface;
    final border = theme.colorScheme.primary.withAlpha(isDark ? 40 : 30);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
