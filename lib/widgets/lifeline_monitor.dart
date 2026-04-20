import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class LifelineMonitor extends StatefulWidget {
  final bool isTyping;

  const LifelineMonitor({super.key, required this.isTyping});

  @override
  State<LifelineMonitor> createState() => _LifelineMonitorState();
}

class _LifelineMonitorState extends State<LifelineMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isTyping) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(covariant LifelineMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedOpacity(
                opacity: widget.isTyping ? 1.0 : 0.0,
                duration: 300.ms,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 50,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(102),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(30, 15),
                              painter: ECGPainter(
                                isTyping: widget.isTyping,
                                progress: _pulseController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate(target: widget.isTyping ? 1 : 0)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
                duration: 400.ms,
              )
              .slideY(begin: 0.5, end: 0, duration: 400.ms),
        ],
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final bool isTyping;
  final double progress;

  ECGPainter({required this.isTyping, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricRose.withAlpha(230)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;

    if (!isTyping) {
      path.moveTo(0, centerY);
      path.lineTo(size.width, centerY);
    } else {
      for (double i = 0; i <= size.width; i++) {
        final localX = (i + (progress * size.width)) % size.width;
        final normalizedX = localX / size.width;

        double y = centerY;

        // Compact ECG peaks for bubble size
        if (normalizedX > 0.2 && normalizedX < 0.25) {
          y -= 1; // P
        } else if (normalizedX >= 0.3 && normalizedX < 0.32) {
          y += 1; // Q
        } else if (normalizedX >= 0.32 && normalizedX < 0.35) {
          y -= 10; // R
        } else if (normalizedX >= 0.35 && normalizedX < 0.38) {
          y += 4; // S
        } else if (normalizedX >= 0.5 && normalizedX < 0.6) {
          y -= 2; // T
        }

        if (i == 0) {
          path.moveTo(i, y);
        } else {
          path.lineTo(i, y);
        }
      }
    }

    canvas.drawPath(path, paint);

    if (isTyping) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.electricRose.withAlpha(77)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) => true;
}
