import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';

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
    
    // In a real app with Algolia, this would be full-text search. 
    // Here we do a basic prefix search or exact match for simplicity.
    final firestore = ref.read(firestoreServiceProvider);
    
    // Search by email exact match
    final querySnapshot = await firestore.searchUsersByEmail(query.trim().toLowerCase());
    
    final currentUid = ref.read(currentUserProvider).value?.uid;
    
    setState(() {
      _searchResults = querySnapshot.where((user) => user.uid != currentUid).toList();
      _isLoading = false;
    });
  }

  void _startChat(UserModel otherUser) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final firestore = ref.read(firestoreServiceProvider);
    
    // Create or get existing chat
    String chatId = await firestore.createOrGetChat(currentUser.uid, otherUser, currentUser);
    
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

    await ref.read(firestoreServiceProvider).sendFriendRequest(currentUser, otherUser);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
      setState(() {}); // Refresh list to show 'Pending'
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider).value?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: AnimatedGradientBg(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search user by exact email...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(150)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withAlpha(30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _searchUsers,
              ),
            ),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty 
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty 
                                ? 'Type an email and hit Enter to search' 
                                : 'No users found',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return FutureBuilder<String>(
                              future: ref.read(firestoreServiceProvider).getFriendshipStatus(
                                currentUid ?? '', 
                                user.uid,
                              ),
                              builder: (context, snapshot) {
                                final status = snapshot.data ?? 'none';
                                
                                String trailingText = '';
                                IconData? trailingIcon;
                                VoidCallback? onTap;

                                if (status == 'friends') {
                                  trailingText = 'Message';
                                  trailingIcon = Icons.chat;
                                  onTap = () => _startChat(user);
                                } else if (status == 'pending_sent') {
                                  trailingText = 'Request Sent';
                                  trailingIcon = Icons.hourglass_empty;
                                } else if (status == 'pending_received') {
                                  trailingText = 'Check Requests';
                                  trailingIcon = Icons.person_add;
                                } else {
                                  trailingText = 'Add Friend';
                                  trailingIcon = Icons.add;
                                  onTap = () => _sendRequest(user);
                                }

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: user.photoUrl != null 
                                        ? NetworkImage(user.photoUrl!) 
                                        : null,
                                    child: user.photoUrl == null 
                                        ? Text(user.displayName[0]) 
                                        : null,
                                  ),
                                  title: Text(user.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(user.email, style: const TextStyle(color: Colors.white70)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(trailingIcon, color: Colors.white70, size: 20),
                                      const SizedBox(height: 4),
                                      Text(trailingText, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                  onTap: onTap,
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
