import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exceptions.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final credential = await _auth.signInWithPopup(googleProvider);
        AppLogger.talker.info(
          'Google sign in successful (web): ${credential.user?.uid}',
        );
        return credential;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          AppLogger.talker.warning('Google sign in cancelled by user');
          throw AuthException(errorType: AuthErrorType.googleSignInFailed);
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        AppLogger.talker.info(
          'Google sign in successful (mobile): ${userCredential.user?.uid}',
        );
        return userCredential;
      }
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.talker.error('Google sign in failed', e, st);
      throw _handleAuthException(e);
    } catch (e, st) {
      AppLogger.talker.error('Google sign in error', e, st);
      throw AuthException(errorType: AuthErrorType.googleSignInFailed);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      AppLogger.talker.info('Signing out user: ${_auth.currentUser?.uid}');
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      AppLogger.talker.info('Sign out successful');
    } catch (e, st) {
      AppLogger.talker.error('Sign out failed', e, st);
      throw AuthException(errorType: AuthErrorType.signOutFailed);
    }
  }

  /// Delete all local data (for account switching)
  Future<void> clearLocalData() async {
    try {
      AppLogger.talker.info('Clearing local data for account switch');
    } catch (e, st) {
      AppLogger.talker.error('Failed to clear local data', e, st);
    }
  }

  /// Convert FirebaseAuthException to typed AppException.
  AuthException _handleAuthException(FirebaseAuthException e) {
    final errorType = switch (e.code) {
      'user-not-found' => AuthErrorType.userNotFound,
      'wrong-password' => AuthErrorType.invalidCredentials,
      'invalid-credential' => AuthErrorType.invalidCredentials,
      'email-already-in-use' => AuthErrorType.emailAlreadyInUse,
      'invalid-email' => AuthErrorType.invalidCredentials,
      'weak-password' => AuthErrorType.weakPassword,
      'operation-not-allowed' => AuthErrorType.unknown,
      'user-disabled' => AuthErrorType.userDisabled,
      'too-many-requests' => AuthErrorType.tooManyRequests,
      'network-request-failed' => AuthErrorType.networkError,
      _ => AuthErrorType.unknown,
    };

    return AuthException(
      errorType: errorType,
      technicalDetails: 'FirebaseAuth: ${e.code} - ${e.message}',
      originalException: e,
    );
  }
}
