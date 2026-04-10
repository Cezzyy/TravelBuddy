import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';
import '../../../../core/logging/app_logger.dart';

part 'auth_provider.g.dart';

/// Provides the current Firebase auth state (User or null).
@riverpod
Stream<auth.User?> authState(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
}

/// Controller for email authentication actions.
@riverpod
class EmailAuthController extends _$EmailAuthController {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Sign in with email and password.
  Future<void> signIn({required String email, required String password}) async {
    final authRepo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await authRepo.signInWithEmail(email: email, password: password);
      // That's it! No local DB sync here
    });

    if (ref.mounted) {
      state = result;
    }
  }

  /// Sign up with email and password.
  Future<void> signUp({required String email, required String password}) async {
    final authRepo = ref.read(authRepositoryProvider);
    final firestore = FirebaseFirestore.instance;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signUpWithEmail(
        email: email,
        password: password,
      );

      // Create user document in Firestore only
      if (credential.user != null) {
        final uid = credential.user!.uid;
        await firestore.collection('users').doc(uid).set({
          'email': credential.user!.email ?? '',
          'displayName': credential.user!.displayName,
          'photoUrl': credential.user!.photoURL,
          'isProfileComplete': false,
          'hasAgreedToRules': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.talker.info('New user created in Firestore: $uid');
      }
    });

    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> signInWithGoogle() async {
    final authRepo = ref.read(authRepositoryProvider);
    final firestore = FirebaseFirestore.instance;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signInWithGoogle();

      if (credential.user != null) {
        final uid = credential.user!.uid;
        final docRef = firestore.collection('users').doc(uid);
        final docSnapshot = await docRef.get();

        // Only create document if it doesn't exist (new user)
        if (!docSnapshot.exists) {
          await docRef.set({
            'email': credential.user!.email ?? '',
            'displayName': credential.user!.displayName,
            'photoUrl': credential.user!.photoURL,
            'isProfileComplete': false,
            'hasAgreedToRules': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          AppLogger.talker.info('New Google user created in Firestore: $uid');
        } else {
          AppLogger.talker.info('Existing Google user signed in: $uid');
        }
      }
    });

    if (ref.mounted) {
      state = result;
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      // Clear all local data before signing out
      await userRepo.clearAllLocalData();

      await repository.signOut();
      if (ref.mounted) {
        state = const AsyncData(null);
      }
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}
