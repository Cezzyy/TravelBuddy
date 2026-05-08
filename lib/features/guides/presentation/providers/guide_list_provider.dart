import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/guide_repository.dart';

/// Provider for published guides list (discovery/browse).
final publishedGuidesProvider = StreamProvider<List<Guide>>((ref) {
  final repo = ref.watch(guideRepositoryProvider);
  return repo.watchPublishedGuides(limit: 50);
});

/// Provider for popular guides (sorted by likes).
final popularGuidesProvider = FutureProvider<List<Guide>>((ref) async {
  final repo = ref.watch(guideRepositoryProvider);
  final guides = await repo.getPublishedGuides(limit: 20);
  guides.sort((a, b) => b.likeCount.compareTo(a.likeCount));
  return guides;
});

/// Provider for recent guides.
final recentGuidesProvider = FutureProvider<List<Guide>>((ref) async {
  final repo = ref.watch(guideRepositoryProvider);
  return repo.getPublishedGuides(limit: 20);
});
