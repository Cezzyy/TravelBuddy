import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/trip_itinerary_repository.dart';

/// Provider for trip itinerary items.
final tripItineraryProvider =
    StreamProvider.family<List<ItineraryItem>, String>((ref, tripId) {
      final repo = ref.watch(tripItineraryRepositoryProvider);
      return repo.watchTripItinerary(tripId);
    });
