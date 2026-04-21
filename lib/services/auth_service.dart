import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final FirestoreService _firestoreService = FirestoreService();
  final MessagingService _messagingService = MessagingService();

  static const List<String> _requiredTables = <String>[
    'users',
    'chats',
    'messages',
    'friend_requests',
  ];

  bool _mentionsRequiredTable(String message) {
    for (final table in _requiredTables) {
      if (message.contains(table)) {
        return true;
      }
    }
    return false;
  }

  bool _isMissingTableError(Object error) {
    final message = error.toString().toLowerCase();
    return _mentionsRequiredTable(message) &&
        (message.contains('does not exist') ||
            message.contains('relation') ||
            message.contains('could not find the table'));
  }

  bool _isSchemaCompatibilityError(Object error) {
    final message = error.toString().toLowerCase();
    return _isMissingTableError(error) ||
        (message.contains('schema cache') && _mentionsRequiredTable(message)) ||
        message.contains('column') &&
            (message.contains('does not exist') ||
                message.contains('not found'));
  }

  UserModel _fallbackUserFromAuth(User user, {String? preferredDisplayName}) {
    final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
    return UserModel(
      uid: user.id,
      email: user.email ?? '',
      displayName:
          preferredDisplayName ??
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['displayName'] as String? ??
          user.email?.split('@').first ??
          'User',
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      lastSeen: DateTime.now(),
      isOnline: true,
      createdAt: createdAt,
    );
  }

  Never _throwFriendly(Object error) {
    if (error is AuthApiException &&
        error.code == 'over_email_send_rate_limit') {
      throw Exception(
        'Too many sign-up attempts right now. Please wait a few minutes, or disable email confirmation in Supabase Auth settings while developing.',
      );
    }

    if (_isMissingTableError(error)) {
      throw Exception(
        'Supabase table setup is missing. Run the SQL schema setup script for users/chats/messages/friend_requests in your Supabase SQL editor.',
      );
    }

    if (_isSchemaCompatibilityError(error)) {
      throw Exception(
        'Supabase schema looks incomplete for this app version. Re-run supabase/schema.sql to add missing columns/policies.',
      );
    }

    throw Exception(error.toString());
  }

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
        try {
          // Update last seen/profile when schema supports full app fields.
          await _firestoreService.updateUserPresence(user.id, true);
          final profile = await _firestoreService.getUser(user.id);
          return profile ?? _fallbackUserFromAuth(user);
        } catch (error) {
          if (_isSchemaCompatibilityError(error)) {
            return _fallbackUserFromAuth(user);
          }
          _throwFriendly(error);
        }
      }
      return null;
    } catch (error) {
      _throwFriendly(error);
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

        try {
          await _firestoreService.createUser(newUser);
        } catch (error) {
          if (!_isSchemaCompatibilityError(error)) {
            _throwFriendly(error);
          }
        }
        return newUser;
      }
      return null;
    } catch (error) {
      _throwFriendly(error);
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
        final fallbackUser = _fallbackUserFromAuth(user);

        try {
          UserModel? existingUser = await _firestoreService.getUser(user.id);

          if (existingUser == null) {
            existingUser = fallbackUser;
            await _firestoreService.createUser(existingUser);
          } else {
            await _firestoreService.updateUserPresence(user.id, true);
          }

          return existingUser;
        } catch (error) {
          if (_isSchemaCompatibilityError(error)) {
            return fallbackUser;
          }
          _throwFriendly(error);
        }
      }
      return null;
    } catch (error) {
      _throwFriendly(error);
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.updateUserPresence(user.id, false);
        try {
          await _messagingService.clearToken(user.id);
        } catch (_) {
          // Best effort only.
        }
      }
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (error) {
      _throwFriendly(error);
    }
  }
}
