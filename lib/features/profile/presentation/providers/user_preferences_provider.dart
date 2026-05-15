import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/user_repository.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../../shared/data/app_db.dart';

/// Provider for watching user preferences
final userPreferencesProvider = StreamProvider<UserPreference?>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value(null);
  }

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUserPreferences(currentUser.id);
});

/// Provider for updating user preferences
final updateUserPreferencesProvider =
    Provider<
      Future<void> Function({
        String? travelStyle,
        String? budgetLevel,
        String? preferredActivities,
      })
    >((ref) {
      return ({
        String? travelStyle,
        String? budgetLevel,
        String? preferredActivities,
      }) async {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) {
          throw Exception('No user logged in');
        }

        final userRepo = ref.read(userRepositoryProvider);
        await userRepo.updateUserPreferences(
          userId: currentUser.id,
          travelStyle: travelStyle,
          budgetLevel: budgetLevel,
          preferredActivities: preferredActivities,
        );
      };
    });
