import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';

part 'auth_repository.g.dart';

/// Repository for Firebase Authentication operations.
/// Handles sign-in, sign-up, sign-out, and auth state changes.
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(FirebaseAuth.instance);
}

class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Stream of auth state changes (logged in/out).
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Current user (null if not authenticated).
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.talker.info('Attempting sign in for: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.talker.info('Sign in successful: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.talker.error('Sign in failed', e, st);
      throw _handleAuthException(e);
    }
  }

  /// Create new account with email and password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.talker.info('Attempting sign up for: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.talker.info('Sign up successful: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.talker.error('Sign up failed', e, st);
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      AppLogger.talker.info('Attempting Google sign in');
      final googleProvider = GoogleAuthProvider();

      final credential = kIsWeb
          ? await _auth.signInWithPopup(googleProvider)
          : await _auth.signInWithProvider(googleProvider);

      AppLogger.talker.info(
        'Google sign in successful: ${credential.user?.uid}',
      );
      return credential;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.talker.error('Google sign in failed', e, st);
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      AppLogger.talker.info('Signing out user: ${_auth.currentUser?.uid}');
      await _auth.signOut();
      AppLogger.talker.info('Sign out successful');
    } catch (e, st) {
      AppLogger.talker.error('Sign out failed', e, st);
      rethrow;
    }
  }

  /// Convert FirebaseAuthException to user-friendly messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
