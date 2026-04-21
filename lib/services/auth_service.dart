import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges {
    final stream = _auth.onAuthStateChange.map((data) => data.session?.user);
    final current = _auth.currentUser;
    if (current != null) {
      return Stream<User?>.multi((controller) {
        controller.add(current);
        final sub = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = sub.cancel;
      });
    }
    return stream;
  }

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user != null) {
        // Update last seen
        await _firestoreService.updateUserPresence(user.id, true);
        return await _firestoreService.getUser(user.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'displayName': displayName},
      );

      final user = response.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.id,
          email: user.email ?? '',
          displayName: displayName,
          lastSeen: DateTime.now(),
          isOnline: true,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(newUser);
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );
      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken ?? '',
        accessToken: authz?.accessToken,
      );

      final user = _auth.currentUser;

      if (user != null) {
        UserModel? existingUser = await _firestoreService.getUser(user.id);

        if (existingUser == null) {
          existingUser = UserModel(
            uid: user.id,
            email: user.email ?? '',
            displayName:
                user.userMetadata?['full_name'] as String? ??
                user.email?.split('@').first ??
                'User',
            photoUrl: user.userMetadata?['avatar_url'] as String?,
            lastSeen: DateTime.now(),
            isOnline: true,
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(existingUser);
        } else {
          await _firestoreService.updateUserPresence(user.id, true);
        }

        return existingUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.updateUserPresence(user.id, false);
      }
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
