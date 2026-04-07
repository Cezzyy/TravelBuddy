import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';

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
    final userRepo = ref.read(userRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      // Sign in with Firebase
      final credential = await authRepo.signInWithEmail(
        email: email,
        password: password,
      );

      // Sync user to local DB
      if (credential.user != null) {
        await userRepo.syncUserFromAuth(credential.user!);
      }
    });

    if (ref.mounted) {
      state = result;
    }
  }

  /// Sign up with email and password.
  Future<void> signUp({required String email, required String password}) async {
    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      // Create account with Firebase
      final credential = await authRepo.signUpWithEmail(
        email: email,
        password: password,
      );

      // Sync new user to local DB and Firestore
      if (credential.user != null) {
        await userRepo.syncUserFromAuth(credential.user!);
      }
    });

    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> signInWithGoogle() async {
    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signInWithGoogle();
      if (credential.user != null) {
        await userRepo.syncUserFromAuth(credential.user!);
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

    try {
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
