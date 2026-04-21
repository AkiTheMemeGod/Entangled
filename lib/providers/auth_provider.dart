import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).streamUser(user.id);
  }
  return const Stream.empty();
});

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).streamUser(uid);
});
