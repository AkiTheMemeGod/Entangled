import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/friend_request_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_gradient_bg.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: AnimatedGradientBg(
        child: requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  'No pending requests.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              itemCount: requests.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      backgroundImage: request.fromPhoto != null
                          ? NetworkImage(request.fromPhoto!)
                          : null,
                      child: request.fromPhoto == null
                          ? Text(request.fromName[0])
                          : null,
                    ),
                    title: Text(
                      request.fromName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      request.fromEmail,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _acceptRequest(context, ref, request),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectRequest(context, ref, request),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _acceptRequest(BuildContext context, WidgetRef ref, dynamic request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    await ref.read(firestoreServiceProvider).acceptFriendRequest(request, currentUser);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted!')),
      );
    }
  }

  void _rejectRequest(BuildContext context, WidgetRef ref, dynamic request) async {
    await ref.read(firestoreServiceProvider).rejectFriendRequest(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request ignored.')),
      );
    }
  }
}
