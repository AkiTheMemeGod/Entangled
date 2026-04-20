import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';
import '../../widgets/holographic_avatar.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    final firestore = ref.read(firestoreServiceProvider);
    final querySnapshot = await firestore.searchUsersByEmail(
      query.trim().toLowerCase(),
    );

    final currentUid = ref.read(currentUserProvider).value?.uid;

    setState(() {
      _searchResults = querySnapshot
          .where((user) => user.uid != currentUid)
          .toList();
      _isLoading = false;
    });
  }

  void _startChat(UserModel otherUser) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final firestore = ref.read(firestoreServiceProvider);
    String chatId = await firestore.createOrGetChat(
      currentUser.uid,
      otherUser,
      currentUser,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.chat,
        arguments: {
          'chatId': chatId,
          'otherUserId': otherUser.uid,
          'otherUserName': otherUser.displayName,
          'otherUserPhoto': otherUser.photoUrl,
        },
      );
    }
  }

  void _sendRequest(UserModel otherUser) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    await ref
        .read(firestoreServiceProvider)
        .sendFriendRequest(currentUser, otherUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent!', style: GoogleFonts.outfit()),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Friend',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBg(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.isDarkMode(context) ? AppColors.glassHeavy : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                  cursorColor: AppColors.radiantViolet,
                  decoration: InputDecoration(
                    hintText: 'Enter exact email address...',
                    hintStyle: GoogleFonts.outfit(color: Theme.of(context).hintColor),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.radiantViolet,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onSubmitted: _searchUsers,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.radiantViolet,
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 80,
                            color: AppColors.textDim.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Search for your friends by email'
                                : 'No matching user found',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return FutureBuilder<String>(
                          future: ref
                              .read(firestoreServiceProvider)
                              .getFriendshipStatus(currentUid ?? '', user.uid),
                          builder: (context, snapshot) {
                            final status = snapshot.data ?? 'none';

                            String trailingText = '';
                            IconData? trailingIcon;
                            Color? color;
                            VoidCallback? onTap;

                            if (status == 'friends') {
                              trailingText = 'Message';
                              trailingIcon = Icons.chat_bubble_rounded;
                              color = AppColors.radiantViolet;
                              onTap = () => _startChat(user);
                            } else if (status == 'pending_sent') {
                              trailingText = 'Pending';
                              trailingIcon = Icons.timer_rounded;
                              color = AppColors.textMuted;
                            } else if (status == 'pending_received') {
                              trailingText = 'Requests';
                              trailingIcon = Icons.person_add_rounded;
                              color = AppColors.electricRose;
                            } else {
                              trailingText = 'Add';
                              trailingIcon = Icons.add_rounded;
                              color = AppColors.radiantViolet;
                              onTap = () => _sendRequest(user);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.isDarkMode(context) ? AppColors.glassHeavy : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: HolographicAvatar(
                                    uid: user.uid,
                                    radius: 28,
                                    fallbackPhotoUrl: user.photoUrl,
                                    fallbackName: user.displayName,
                                  ),
                                  title: Text(
                                    user.displayName,
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user.email,
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: GestureDetector(
                                    onTap: onTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (onTap != null)
                                            ? color?.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (onTap != null)
                                              ? color!.withOpacity(0.3)
                                              : AppColors.glassBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            trailingIcon,
                                            color: color,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            trailingText,
                                            style: GoogleFonts.outfit(
                                              color: color,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
