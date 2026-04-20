import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_request_provider.dart';
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No conversations yet.',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Add friends to start chatting!',
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).hintColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: chats.length,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildChatTile(
                            context,
                            chats[index],
                            currentUser?.uid,
                          ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.radiantViolet.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.searchUsers);
          },
          backgroundColor: AppColors.radiantViolet,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entangled',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Quantum Encrypted',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.radiantViolet,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              requestsAsync.when(
                data: (requests) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.glassBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.friendRequests,
                          ),
                        ),
                      ),
                      if (requests.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.electricRose,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread
                ? Colors.white.withOpacity(0.08)
                : AppColors.glassBase,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread
                  ? AppColors.radiantViolet.withOpacity(0.3)
                  : AppColors.glassBorder,
              width: 1,
            ),
          ),
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
                        color: AppColors.electricRose,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.obsidianBase,
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
              child: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  color: isUnread
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
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
                        ? AppColors.radiantViolet
                        : AppColors.textMuted,
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
                      color: AppColors.radiantViolet,
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
      ),
    );
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
