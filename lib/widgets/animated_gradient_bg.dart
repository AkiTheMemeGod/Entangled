import 'package:flutter/material.dart';

class AnimatedGradientBg extends StatelessWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(color: theme.scaffoldBackgroundColor, child: child);
  }
}
