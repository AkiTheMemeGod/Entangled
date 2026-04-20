import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/routes.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_request_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';
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
          child: Column(
            children: [
              _buildAppBar(context, ref, currentUser),
              Expanded(
                child: chatsAsyncValue.when(
                  data: (chats) {
                    if (chats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No conversations yet. Add friends to start chatting!',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: chats.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return _buildChatTile(context, chats[index], currentUser?.uid);
                      },
                    );
                  },
                  loading: () => const ShimmerChartList(),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.searchUsers);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          Row(
            children: [
              requestsAsync.when(
                data: (requests) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people_outline, color: Colors.white),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.friendRequests),
                      ),
                      if (requests.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                child: Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatModel chat, String? currentUserId) {
    if (currentUserId == null) return const SizedBox.shrink();

    String otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    String otherUserName = chat.participantNames[otherUserId] ?? 'Unknown';
    String? otherUserPhoto = chat.participantPhotos[otherUserId];
    
    bool isUnread = (chat.unreadCount[currentUserId] ?? 0) > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight.withOpacity(0.5),
            backgroundImage: otherUserPhoto != null
                ? CachedNetworkImageProvider(otherUserPhoto)
                : null,
            child: otherUserPhoto == null
                ? Text(otherUserName.substring(0, 1).toUpperCase())
                : null,
          ),
          // Online indicator could be added here if we track it in ChatModel or load separate stream
        ],
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          color: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount[currentUserId]}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ]
        ],
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
