import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';

/// Provides the current local user data from Drift based on Firebase auth state.
/// Returns null if user is not authenticated.
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  await for (final firebaseUser in authRepo.authStateChanges()) {
    if (firebaseUser == null) {
      // No user authenticated, yield null immediately
      yield null;
      continue;
    }

    // User authenticated, watch their local data
    // The stream will automatically update when the database changes
    await for (final localUser in userRepo.watchLocalUser(firebaseUser.uid)) {
      yield localUser;
    }
  }
});
