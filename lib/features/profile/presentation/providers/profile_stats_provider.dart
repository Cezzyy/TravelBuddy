import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../trips/data/trip_repository.dart';
import '../../../guides/data/guide_repository.dart';

/// Provider for user's trip statistics.
final userTripStatsProvider = FutureProvider<TripStats>((ref) async {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return const TripStats(tripCount: 0, placesCount: 0, totalDays: 0);
  }

  final tripRepo = ref.watch(tripRepositoryProvider);
  final trips = await tripRepo.getMyTrips(currentUser.id);

  // Calculate stats
  final tripCount = trips.length;

  // Count unique destinations (places)
  final uniquePlaces = trips.map((t) => t.destination).toSet().length;

  // Calculate total days across all trips
  var totalDays = 0;
  for (final trip in trips) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    totalDays += days;
  }

  return TripStats(
    tripCount: tripCount,
    placesCount: uniquePlaces,
    totalDays: totalDays,
  );
});

/// Provider for user's guide statistics.
final userGuideStatsProvider = FutureProvider<GuideStats>((ref) async {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return const GuideStats(
      totalGuides: 0,
      publishedGuides: 0,
      totalLikes: 0,
      totalViews: 0,
    );
  }

  final guideRepo = ref.watch(guideRepositoryProvider);
  final guides = await guideRepo.getMyGuides(currentUser.id);

  final totalGuides = guides.length;
  final publishedGuides = guides.where((g) => g.isPublished).length;

  var totalLikes = 0;
  var totalViews = 0;
  for (final guide in guides) {
    totalLikes += guide.likeCount;
    totalViews += guide.viewCount;
  }

  return GuideStats(
    totalGuides: totalGuides,
    publishedGuides: publishedGuides,
    totalLikes: totalLikes,
    totalViews: totalViews,
  );
});

/// Model for trip statistics.
class TripStats {
  const TripStats({
    required this.tripCount,
    required this.placesCount,
    required this.totalDays,
  });

  final int tripCount;
  final int placesCount;
  final int totalDays;
}

/// Model for guide statistics.
class GuideStats {
  const GuideStats({
    required this.totalGuides,
    required this.publishedGuides,
    required this.totalLikes,
    required this.totalViews,
  });

  final int totalGuides;
  final int publishedGuides;
  final int totalLikes;
  final int totalViews;
}
