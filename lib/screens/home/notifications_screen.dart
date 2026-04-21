import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: () async {
              final uid = ref.read(authStateProvider).value?.id;
              if (uid == null) return;
              await ref
                  .read(firestoreServiceProvider)
                  .markAllNotificationsAsRead(uid);
            },
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: AnimatedGradientBg(
        child: notificationsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No notifications yet.',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationTile(item: item);
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
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileColor = item.isRead
        ? (AppColors.isDarkMode(context)
              ? AppColors.glassHeavy
              : Colors.white.withAlpha(128))
        : Theme.of(context).colorScheme.primary.withAlpha(25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: Icon(
            Icons.notifications_active_rounded,
            color: item.isRead
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            item.title,
            style: GoogleFonts.outfit(
              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          trailing: Text(
            _formatTime(item.createdAt),
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () async {
            await ref
                .read(firestoreServiceProvider)
                .markNotificationAsRead(item.id);

            if (!context.mounted) return;
            Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {
                'chatId': item.chatId,
                'otherUserId': item.senderId,
                'otherUserName': item.title,
                'otherUserPhoto': null,
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${time.month}/${time.day}';
  }
}
