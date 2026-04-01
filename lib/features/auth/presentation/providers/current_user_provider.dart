import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';

/// Provides the current local user data from Drift based on Firebase auth state.
/// Returns null if user is not authenticated.
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  final currentFirebaseUser = authRepo.currentUser;

  if (currentFirebaseUser == null) {
    return Stream.value(null);
  }

  return userRepo.watchLocalUser(currentFirebaseUser.uid);
});
