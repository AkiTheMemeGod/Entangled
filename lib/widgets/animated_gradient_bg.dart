import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AnimatedGradientBg extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bool isDark = AppColors.isDarkMode(context);

    _color1 = ColorTween(
      begin: isDark ? AppColors.bgDark : AppColors.bgLight,
      end: isDark ? const Color(0xFF151530) : const Color(0xFFE8E8FF),
    ).animate(_controller);

    _color2 = ColorTween(
      begin: isDark ? const Color(0xFF1A1025) : const Color(0xFFE0F7FA),
      end: isDark ? AppColors.bgDark : AppColors.bgLight,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color1.value ?? AppColors.bgDark,
                _color2.value ?? AppColors.bgDark,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
