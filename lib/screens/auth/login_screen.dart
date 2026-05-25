import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/glassmorphism.dart';
import '../../widgets/animated_gradient_bg.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedGradientBg(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + wordmark
                Column(
                  children: [
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
                                color: scheme.primary.withAlpha(120),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            size: 32,
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
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: Text(
                            'Entangled',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 500.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: 120.ms,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: scheme.onSurface.withAlpha(160),
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  ],
                ),
                const SizedBox(height: 36),

                // Card
                GlassCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          _FieldLabel(label: 'Email'),
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
                          const SizedBox(height: 20),

                          // Password field
                          _FieldLabel(label: 'Password'),
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
                          const SizedBox(height: 28),

                          // Sign in button
                          GestureDetector(
                            onTap: _isLoading ? null : _login,
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
                                          color: scheme.primary.withAlpha(100),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
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
                                        'Sign In',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white.withAlpha(30)
                                      : Colors.black.withAlpha(20),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: GoogleFonts.outfit(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white.withAlpha(30)
                                      : Colors.black.withAlpha(20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google button
                          GestureDetector(
                            onTap: _isLoading ? null : _loginWithGoogle,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withAlpha(30)
                                      : Colors.black.withAlpha(18),
                                ),
                                color: isDark
                                    ? Colors.white.withAlpha(8)
                                    : Colors.white.withAlpha(200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 26,
                                    color: scheme.onSurface,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.outfit(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      delay: 280.ms,
                      duration: 450.ms,
                    ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.outfit(
                        color: scheme.onSurface.withAlpha(160),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.signup,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
