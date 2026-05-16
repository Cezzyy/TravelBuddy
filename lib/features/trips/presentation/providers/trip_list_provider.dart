import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/trip_repository.dart';

/// Provider for all user's trips (owned + collaborated).
final myTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchAllUserTrips(currentUser.id);
});

/// Provider for upcoming trips (owned + collaborated).
final upcomingTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchAllUpcomingTrips(currentUser.id);
});

/// Provider for past trips (owned + collaborated).
final pastTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchAllPastTrips(currentUser.id);
});
