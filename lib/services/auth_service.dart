import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges {
    // Firebase Auth has threading issues on Windows
    if (kIsWeb || Platform.isWindows) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  User? get currentUser {
    if (kIsWeb || Platform.isWindows) {
      return null;
    }
    return _auth.currentUser;
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    if (kIsWeb || Platform.isWindows) {
      throw UnsupportedError('Authentication not supported on this platform');
    }
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update last seen
        await _firestoreService.updateUserPresence(
          userCredential.user!.uid,
          true,
        );
        return await _firestoreService.getUser(userCredential.user!.uid);
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
    if (kIsWeb || Platform.isWindows) {
      throw UnsupportedError('Authentication not supported on this platform');
    }
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
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
    if (kIsWeb || Platform.isWindows) {
      throw UnsupportedError('Google Sign In not supported on this platform');
    }
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        UserModel? existingUser = await _firestoreService.getUser(user.uid);

        if (existingUser == null) {
          existingUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            lastSeen: DateTime.now(),
            isOnline: true,
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(existingUser);
        } else {
          await _firestoreService.updateUserPresence(user.uid, true);
        }

        return existingUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (kIsWeb || Platform.isWindows) {
      return;
    }
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.updateUserPresence(user.uid, false);
      }
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
