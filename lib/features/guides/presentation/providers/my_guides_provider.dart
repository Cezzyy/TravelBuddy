import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/app_db.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/guide_repository.dart';

/// Provider for current user's guides.
final myGuidesProvider = StreamProvider<List<Guide>>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final repo = ref.watch(guideRepositoryProvider);
  return repo.watchMyGuides(currentUser.id);
});

/// Provider for current user's published guides.
final myPublishedGuidesProvider = StreamProvider<List<Guide>>((ref) {
  final guidesAsync = ref.watch(myGuidesProvider);
  
  return guidesAsync.when(
    data: (list) => Stream.value(list.where((guide) => guide.isPublished).toList()),
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

/// Provider for current user's draft guides.
final myDraftGuidesProvider = StreamProvider<List<Guide>>((ref) {
  final guidesAsync = ref.watch(myGuidesProvider);
  
  return guidesAsync.when(
    data: (list) => Stream.value(list.where((guide) => !guide.isPublished).toList()),
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

/// Provider for guide statistics.
final myGuideStatsProvider = StreamProvider<GuideStats>((ref) {
  final guidesAsync = ref.watch(myGuidesProvider);
  
  return guidesAsync.when(
    data: (list) {
      final published = list.where((g) => g.isPublished).toList();
      final drafts = list.where((g) => !g.isPublished).toList();
      
      final totalViews = published.fold<int>(
        0, 
        (sum, guide) => sum + guide.viewCount,
      );
      
      final totalLikes = published.fold<int>(
        0, 
        (sum, guide) => sum + guide.likeCount,
      );
      
      return Stream.value(GuideStats(
        totalGuides: list.length,
        publishedCount: published.length,
        draftCount: drafts.length,
        totalViews: totalViews,
        totalLikes: totalLikes,
      ));
    },
    loading: () => Stream.value(const GuideStats(
      totalGuides: 0,
      publishedCount: 0,
      draftCount: 0,
      totalViews: 0,
      totalLikes: 0,
    )),
    error: (_, _) => Stream.value(const GuideStats(
      totalGuides: 0,
      publishedCount: 0,
      draftCount: 0,
      totalViews: 0,
      totalLikes: 0,
    )),
  );
});

/// Guide statistics model.
class GuideStats {
  const GuideStats({
    required this.totalGuides,
    required this.publishedCount,
    required this.draftCount,
    required this.totalViews,
    required this.totalLikes,
  });

  final int totalGuides;
  final int publishedCount;
  final int draftCount;
  final int totalViews;
  final int totalLikes;
}
