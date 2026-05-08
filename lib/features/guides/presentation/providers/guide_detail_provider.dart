import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/data/app_db.dart';
import '../../data/guide_engagement_repository.dart';
import '../../data/guide_itinerary_repository.dart';
import '../../data/guide_repository.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

part 'guide_detail_provider.g.dart';

/// Watch a single guide by ID.
final guideDetailProvider = StreamProvider.family<Guide?, String>((
  ref,
  guideId,
) {
  final repo = ref.watch(guideRepositoryProvider);
  return repo.watchGuide(guideId);
});

/// Watch itinerary items for a guide.
final guideItineraryProvider =
    StreamProvider.family<List<GuideItineraryItem>, String>((ref, guideId) {
      final repo = ref.watch(guideItineraryRepositoryProvider);
      return repo.watchGuideItinerary(guideId);
    });

/// Watch comments for a guide.
final guideCommentsProvider = StreamProvider.family<List<GuideComment>, String>(
  (ref, guideId) {
    final repo = ref.watch(guideEngagementRepositoryProvider);
    return repo.watchGuideComments(guideId);
  },
);

/// Watch whether the current user has liked a guide.
final isGuideLikedProvider = StreamProvider.family<bool, String>((
  ref,
  guideId,
) {
  final currentUserAsync = ref.watch(currentUserProvider);
  final currentUser = currentUserAsync.value;

  if (currentUser == null) return Stream.value(false);

  final repo = ref.watch(guideEngagementRepositoryProvider);
  return repo.watchIsGuideLiked(guideId, currentUser.id);
});

/// Notifier for guide detail actions (like, comment, view tracking).
@riverpod
class GuideDetailActions extends _$GuideDetailActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> toggleLike(String guideId) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    if (currentUser == null) return;

    final repo = ref.read(guideEngagementRepositoryProvider);
    final isLiked = await repo.isGuideLiked(guideId, currentUser.id);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (isLiked) {
        await repo.unlikeGuide(guideId, currentUser.id);
      } else {
        await repo.likeGuide(guideId, currentUser.id);
      }
    });
  }

  Future<void> addComment(String guideId, String content) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideEngagementRepositoryProvider);
      await repo.addComment(
        guideId: guideId,
        userId: currentUser.id,
        content: content,
      );
    });
  }

  Future<void> deleteComment(String commentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(guideEngagementRepositoryProvider);
      await repo.deleteComment(commentId);
    });
  }

  Future<void> trackView(String guideId) async {
    final repo = ref.read(guideRepositoryProvider);
    await repo.incrementViewCount(guideId);
  }
}
