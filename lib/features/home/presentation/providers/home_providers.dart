import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../guides/data/guide_repository.dart';
import '../../../trips/data/trip_repository.dart';

/// Provider for featured guides (top published guides by likes).
final featuredGuidesProvider = FutureProvider<List<Guide>>((ref) async {
  final repo = ref.watch(guideRepositoryProvider);
  final guides = await repo.getPublishedGuides(limit: 10);

  // Sort by like count descending
  guides.sort((a, b) => b.likeCount.compareTo(a.likeCount));

  return guides.take(5).toList();
});

/// Provider for upcoming trips on home screen (owned + collaborated).
final homeUpcomingTripsProvider = StreamProvider<List<Trip>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchAllUpcomingTrips(currentUser.id);
});
