import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/trip_invitation_repository.dart';
import '../../domain/trip_role.dart';

/// Watch collaborators for a specific trip
final tripCollaboratorsProvider =
    StreamProvider.family<List<TripCollaborator>, String>((ref, tripId) {
      final repo = ref.watch(tripInvitationRepositoryProvider);
      return repo.watchCollaborators(tripId);
    });

/// Get the current user's role in a trip
final userTripRoleProvider = FutureProvider.family<TripRole?, String>((
  ref,
  tripId,
) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return null;
  }

  final repo = ref.watch(tripInvitationRepositoryProvider);
  return repo.getUserRole(tripId, currentUser.id);
});
