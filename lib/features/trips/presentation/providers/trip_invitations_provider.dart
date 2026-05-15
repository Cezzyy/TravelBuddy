import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/trip_invitation_repository.dart';

/// Watch invitations for a specific trip
final tripInvitationsProvider =
    StreamProvider.family<List<TripInvitation>, String>((ref, tripId) {
      final repo = ref.watch(tripInvitationRepositoryProvider);
      return repo.watchInvitationsForTrip(tripId);
    });

/// Watch pending invitations for the current user
final userPendingInvitationsProvider = StreamProvider<List<TripInvitation>>((
  ref,
) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripInvitationRepositoryProvider);
  return repo.watchInvitationsForUser(currentUser.email);
});

/// Watch count of pending invitations for the current user
final pendingInvitationCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value(0);
  }

  final repo = ref.watch(tripInvitationRepositoryProvider);
  return repo.watchPendingInvitationCount(currentUser.email);
});
