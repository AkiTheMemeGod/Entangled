import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    
    // Check if user is logged in
    if (authState.value != null) {
      // Initialize FCM and save token for push notifications
      final messagingService = MessagingService();
      await messagingService.init(authState.value!.uid);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBg(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
               .then().shimmer(duration: 1.seconds),
              
              const SizedBox(height: 24),
              
              Text(
                'Entangled',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ).animate().fade(delay: 300.ms, duration: 500.ms).slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}

