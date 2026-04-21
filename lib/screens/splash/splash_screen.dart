import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';
import '../../widgets/animated_gradient_bg.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Future<void> _startTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _timerDone = true;
      });
      _checkNavigation();
    }
  }

  void _checkNavigation() {
    if (!_timerDone) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) => _performNavigation(user),
      loading: () {
        // If still loading, ref.listen will handle it when it arrives
      },
      error: (err, stack) => _performNavigation(null),
    );
  }

  Future<void> _performNavigation(User? user) async {
    if (!mounted) return;

    if (user != null) {
      try {
        final messagingService = MessagingService();
        await messagingService
            .init(user.id)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('FCM Init failed: $e');
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and navigate if the timer is already done
    ref.listen(authStateProvider, (previous, next) {
      if (_timerDone) {
        _checkNavigation();
      }
    });

    return Scaffold(
      body: AnimatedGradientBg(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(102),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1.seconds),

              const SizedBox(height: 32),

              Text(
                    'Entangled',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                  .animate()
                  .fade(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
