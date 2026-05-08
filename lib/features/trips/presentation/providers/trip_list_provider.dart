import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/trip_repository.dart';

/// Provider for all user's trips.
final myTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;
  
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchMyTrips(currentUser.id);
});

/// Provider for upcoming trips (upcoming or ongoing status).
final upcomingTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;
  
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchUpcomingTrips(currentUser.id);
});

/// Provider for past trips (completed or cancelled status).
final pastTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;
  
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchPastTrips(currentUser.id);
});
