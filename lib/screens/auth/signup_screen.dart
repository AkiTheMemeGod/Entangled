import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/glassmorphism.dart';
import '../../widgets/animated_gradient_bg.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref
          .read(authServiceProvider)
          .signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign-up started. If email confirmation is enabled, verify your email and then sign in.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedGradientBg(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + wordmark
                Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.primary, scheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withAlpha(100),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scaleXY(
                      begin: 0.8,
                      end: 1.0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 20),
                ShaderMask(
                      shaderCallback: (bounds) =>
                          LinearGradient(
                            colors: [scheme.primary, scheme.secondary],
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      delay: 120.ms,
                      duration: 350.ms,
                    ),
                const SizedBox(height: 6),
                Text(
                  'Join the conversation',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                const SizedBox(height: 32),

                // Card
                GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SignupFieldLabel(label: 'Display Name'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: scheme.primary.withAlpha(200),
                              ),
                            ),
                            style: GoogleFonts.outfit(
                              color: scheme.onSurface,
                              fontSize: 15,
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 18),
                          _SignupFieldLabel(label: 'Email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: scheme.primary.withAlpha(200),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.outfit(
                              color: scheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SignupFieldLabel(label: 'Password'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: scheme.primary.withAlpha(200),
                              ),
                            ),
                            obscureText: true,
                            style: GoogleFonts.outfit(
                              color: scheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 26),

                          // Sign up button
                          GestureDetector(
                            onTap: _isLoading ? null : _signup,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? null
                                    : LinearGradient(
                                        colors: [
                                          scheme.primary,
                                          scheme.secondary,
                                        ],
                                      ),
                                color: _isLoading
                                    ? scheme.primary.withAlpha(80)
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: scheme.primary.withAlpha(90),
                                          blurRadius: 16,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 450.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 280.ms,
                      duration: 400.ms,
                    ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.outfit(
                        color: scheme.onSurface.withAlpha(150),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupFieldLabel extends StatelessWidget {
  final String label;
  const _SignupFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
