import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_request_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';
import '../../widgets/holographic_avatar.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBg(
        child: requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(77),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending requests.',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: requests.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemBuilder: (context, index) {
                final request = requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.isDarkMode(context)
                          ? AppColors.glassHeavy
                          : Colors.white.withAlpha(128),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: HolographicAvatar(
                        uid: request.fromId,
                        radius: 28,
                        fallbackPhotoUrl: request.fromPhoto,
                        fallbackName: request.fromName,
                      ),
                      title: Text(
                        request.fromName,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Text(
                        request.fromEmail,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.close_rounded,
                            color: AppColors.error,
                            onPressed: () =>
                                _rejectRequest(context, ref, request),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.check_rounded,
                            isPrimary: true,
                            onPressed: () =>
                                _acceptRequest(context, ref, request),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.radiantViolet),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: GoogleFonts.outfit(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  void _acceptRequest(
    BuildContext context,
    WidgetRef ref,
    dynamic request,
  ) async {
    var currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      final authUser = ref.read(authStateProvider).value;
      if (authUser != null) {
        currentUser = UserModel(
          uid: authUser.id,
          email: authUser.email ?? '',
          displayName:
              authUser.userMetadata?['full_name'] as String? ??
              authUser.userMetadata?['displayName'] as String? ??
              authUser.email?.split('@').first ??
              'User',
          photoUrl: authUser.userMetadata?['avatar_url'] as String?,
          lastSeen: DateTime.now(),
          isOnline: true,
          createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
        );
      }
    }
    if (currentUser == null) return;

    await ref
        .read(firestoreServiceProvider)
        .acceptFriendRequest(request, currentUser);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request accepted!',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    dynamic request,
  ) async {
    await ref.read(firestoreServiceProvider).rejectFriendRequest(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request ignored.', style: GoogleFonts.outfit()),
          backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.radiantViolet
              : (color ?? Theme.of(context).colorScheme.onSurfaceVariant)
                    .withAlpha(26),
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.radiantViolet.withAlpha(77),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.white
              : (color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          size: 20,
        ),
      ),
    );
  }
}
