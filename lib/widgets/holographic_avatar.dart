import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'full_screen_image_viewer.dart';

class HolographicAvatar extends ConsumerWidget {
  final String uid;
  final double radius;
  final String? fallbackName;
  final String? fallbackPhotoUrl;
  final bool showGlow;
  final String? heroTag;
  final VoidCallback? onTap;

  const HolographicAvatar({
    super.key,
    required this.uid,
    this.radius = 28,
    this.fallbackName,
    this.fallbackPhotoUrl,
    this.showGlow = true,
    this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(uid));

    return userAsync.when(
      data: (user) {
        final photoUrl = user?.photoUrl ?? fallbackPhotoUrl;
        final name = user?.displayName ?? fallbackName ?? '?';

        return _buildAvatar(context, photoUrl, name);
      },
      loading: () => _buildShimmer(),
      error: (err, stack) =>
          _buildAvatar(context, fallbackPhotoUrl, fallbackName ?? '?'),
    );
  }

  Widget _buildAvatar(BuildContext context, String? photoUrl, String name) {
    if (uid.isEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: AppColors.obsidianBase,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(Icons.person, color: AppColors.textDim, size: radius),
        ),
      );
    }

    final effectiveHeroTag = heroTag ?? 'avatar_$uid';

    return GestureDetector(
      onTap: onTap ??
          (photoUrl != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: photoUrl,
                        tag: effectiveHeroTag,
                        name: name,
                      ),
                    ),
                  )
              : null),
      child: Hero(
        tag: effectiveHeroTag,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showGlow
                ? Border.all(
                    color: AppColors.radiantViolet.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: AppColors.radiantViolet.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.obsidianBase,
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: radius * 0.8,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.obsidianBase,
      highlightColor: AppColors.glassBorder,
      child: Container(
        width: (radius + 2) * 2,
        height: (radius + 2) * 2,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
