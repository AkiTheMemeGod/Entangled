import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';
import '../../widgets/holographic_avatar.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final chatsAsyncValue = ref.watch(userChatsProvider);

    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context, ref, currentUser),
              Expanded(
                child: chatsAsyncValue.when(
                  data: (chats) {
                    if (chats.isEmpty) {
                      return _EmptyConversations();
                    }
                    return ListView.builder(
                      itemCount: chats.length,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      itemBuilder: (context, index) {
                        // Only stagger the first 8 tiles (those visible on
                        // launch). Tiles scrolled into view later skip the
                        // animation to avoid spawning surplus controllers.
                        final tile = RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildChatTile(
                              context,
                              ref,
                              chats[index],
                              currentUser?.uid,
                            ),
                          ),
                        );
                        if (index >= 8) return tile;
                        return tile
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: (index * 35).ms,
                              curve: Curves.easeOut,
                            )
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              duration: 300.ms,
                              delay: (index * 35).ms,
                              curve: Curves.easeOut,
                            );
                      },
                    );
                  },
                  loading: () => const ShimmerChartList(),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _GradientFab(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.searchUsers),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  'Entangled',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withAlpha(180),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 1200.ms)
                      .then()
                      .fadeOut(duration: 1200.ms),
                  const SizedBox(width: 8),
                  Text(
                    'QUANTUM ENCRYPTED',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: scheme.primary.withAlpha(220),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
                badgeColor: unreadNotifications > 0 ? scheme.primary : null,
              ),
              const SizedBox(width: 8),
              requestsAsync.when(
                data: (requests) => _GlassIconButton(
                  icon: Icons.person_add_alt_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.friendRequests),
                  badgeColor: requests.isNotEmpty ? scheme.secondary : null,
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              HolographicAvatar(
                uid: user?.uid ?? '',
                radius: 20,
                fallbackPhotoUrl: user?.photoUrl,
                fallbackName: user?.displayName,
                heroTag: 'profile_avatar',
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
    String? currentUserId,
  ) {
    if (currentUserId == null) return const SizedBox.shrink();

    String otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    String otherUserName = chat.participantNames[otherUserId] ?? 'Unknown';
    String? otherUserPhoto = chat.participantPhotos[otherUserId];

    bool isUnread = (chat.unreadCount[currentUserId] ?? 0) > 0;
    final messagesAsync = ref.watch(chatMessagesProvider(chat.id));
    final latestImageBatchCount = messagesAsync.maybeWhen(
      data: (messages) => _latestImageBatchCount(messages),
      orElse: () => 0,
    );
    final subtitleText = latestImageBatchCount > 1
        ? '$latestImageBatchCount images'
        : chat.lastMessage;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? scheme.primary.withAlpha(isDark ? 28 : 18)
            : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnread
              ? scheme.primary.withAlpha(80)
              : scheme.primary.withAlpha(isDark ? 25 : 20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {
                'chatId': chat.id,
                'otherUserId': otherUserId,
                'otherUserName': otherUserName,
                'otherUserPhoto': otherUserPhoto,
              },
            );
          },
          leading: Stack(
            children: [
              HolographicAvatar(
                uid: otherUserId,
                radius: 26,
                fallbackPhotoUrl: otherUserPhoto,
                fallbackName: otherUserName,
              ),
              if (isUnread)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.obsidianBase
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherUserName,
            style: GoogleFonts.outfit(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                if (latestImageBatchCount > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(77),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$latestImageBatchCount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: isUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: isUnread
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(chat.lastMessageTime),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isUnread
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withAlpha(153),
                ),
              ),
              if (isUnread) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${chat.unreadCount[currentUserId]}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _latestImageBatchCount(List<MessageModel> messages) {
    if (messages.isEmpty) return 0;

    final newest = messages.first;
    final isImage =
        newest.type == 'image' && newest.imageUrl != null && !newest.isDeleted;
    if (!isImage) return 0;

    var count = 0;
    for (final message in messages) {
      final sameSender = message.senderId == newest.senderId;
      final imageMessage =
          message.type == 'image' &&
          message.imageUrl != null &&
          !message.isDeleted;
      final closeInTime =
          newest.timestamp.difference(message.timestamp).abs() <=
          const Duration(minutes: 2);

      if (sameSender && imageMessage && closeInTime) {
        count++;
      } else {
        break;
      }
    }

    return count;
  }

  String _formatTime(DateTime time) {
    // Basic formatting without intl to keep code simple for now
    // A production app would use packages like intl or timeago
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.month}/${time.day}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing orb icon
                  Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              scheme.primary.withAlpha(60),
                              scheme.primary.withAlpha(0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withAlpha(80),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 36,
                          color: scheme.primary.withAlpha(200),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.95, end: 1.05, duration: 2400.ms)
                      .then()
                      .scaleXY(begin: 1.05, end: 0.95, duration: 2400.ms),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: GoogleFonts.outfit(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add friends to start chatting',
                    style: GoogleFonts.outfit(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, end: 0, duration: 500.ms),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? badgeColor;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.primary.withAlpha(isDark ? 40 : 30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: scheme.onSurface, size: 20),
          ),
          if (badgeColor != null)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: badgeColor!.withAlpha(180), blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _GradientFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child:
          Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(110),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: scheme.secondary.withAlpha(60),
                      blurRadius: 30,
                      spreadRadius: -4,
                      offset: const Offset(4, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.04, duration: 1800.ms)
              .then()
              .scaleXY(begin: 1.04, end: 1.0, duration: 1800.ms),
    );
  }
}
