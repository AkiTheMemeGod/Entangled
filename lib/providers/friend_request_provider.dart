import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_request_model.dart';
import 'auth_provider.dart';

final incomingRequestsProvider = StreamProvider<List<FriendRequestModel>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).streamIncomingRequests(user.id);
  }
  return Stream.value([]);
});
