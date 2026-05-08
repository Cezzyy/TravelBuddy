import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/trip_repository.dart';

/// Provider for a single trip by ID.
final tripDetailProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchTrip(tripId);
});
