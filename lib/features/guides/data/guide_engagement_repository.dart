import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';
import 'guide_repository.dart';

part 'guide_engagement_repository.g.dart';

/// Repository for guide engagement (likes and comments).
@riverpod
GuideEngagementRepository guideEngagementRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final guideRepo = ref.watch(guideRepositoryProvider);
  return GuideEngagementRepository(db, FirebaseFirestore.instance, guideRepo);
}

class GuideEngagementRepository {
  GuideEngagementRepository(this._db, this._firestore, this._guideRepo);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final GuideRepository _guideRepo;

  // ==================== LIKES ====================

  /// Like a guide.
  Future<void> likeGuide(String guideId, String userId) async {
    final now = DateTime.now();

    // Check if already liked
    final existing =
        await (_db.select(_db.guideLikes)..where(
              (l) => l.guideId.equals(guideId) & l.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      AppLogger.talker.info('Guide already liked: $guideId');
      return;
    }

    // Add like
    await _db
        .into(_db.guideLikes)
        .insert(
          GuideLikesCompanion.insert(
            guideId: guideId,
            userId: userId,
            likedAt: now,
            lastSyncedAt: const drift.Value.absent(),
          ),
        );

    AppLogger.talker.info('Guide liked locally: $guideId');

    // Update guide like count
    await _guideRepo.updateLikeCount(guideId, 1);

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_likes',
      recordId: '$guideId-$userId',
      operation: 'create',
      payload: {
        'guideId': guideId,
        'userId': userId,
        'likedAt': now.toIso8601String(),
      },
    );

    // Attempt immediate sync
    await _syncLikeToFirestore(guideId, userId);
  }

  /// Unlike a guide.
  Future<void> unlikeGuide(String guideId, String userId) async {
    final existing =
        await (_db.select(_db.guideLikes)..where(
              (l) => l.guideId.equals(guideId) & l.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (existing == null) {
      AppLogger.talker.info('Guide not liked: $guideId');
      return;
    }

    // Remove like
    await (_db.delete(
      _db.guideLikes,
    )..where((l) => l.guideId.equals(guideId) & l.userId.equals(userId))).go();

    AppLogger.talker.info('Guide unliked locally: $guideId');

    // Update guide like count
    await _guideRepo.updateLikeCount(guideId, -1);

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_likes',
      recordId: '$guideId-$userId',
      operation: 'delete',
      payload: {'guideId': guideId, 'userId': userId},
    );

    // Attempt immediate sync
    try {
      await _firestore
          .collection('guide_likes')
          .where('guideId', isEqualTo: guideId)
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
            for (final doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
      AppLogger.talker.info('Like removed from Firestore: $guideId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to remove like from Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Check if a guide is liked by a user.
  Future<bool> isGuideLiked(String guideId, String userId) async {
    final like =
        await (_db.select(_db.guideLikes)..where(
              (l) => l.guideId.equals(guideId) & l.userId.equals(userId),
            ))
            .getSingleOrNull();
    return like != null;
  }

  /// Watch if a guide is liked by a user.
  Stream<bool> watchIsGuideLiked(String guideId, String userId) {
    return (_db.select(_db.guideLikes)
          ..where((l) => l.guideId.equals(guideId) & l.userId.equals(userId)))
        .watchSingleOrNull()
        .map((like) => like != null);
  }

  /// Get like count for a guide.
  Future<int> getLikeCount(String guideId) async {
    return await (_db.select(_db.guideLikes)
          ..where((l) => l.guideId.equals(guideId)))
        .get()
        .then((likes) => likes.length);
  }

  // ==================== COMMENTS ====================

  /// Add a comment to a guide.
  Future<GuideComment> addComment({
    required String guideId,
    required String userId,
    required String content,
  }) async {
    final now = DateTime.now();
    final commentId = _firestore.collection('guide_comments').doc().id;

    final companion = GuideCommentsCompanion.insert(
      id: commentId,
      guideId: guideId,
      userId: userId,
      content: content,
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.guideComments).insert(companion);
    AppLogger.talker.info('Comment added locally: $commentId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_comments',
      recordId: commentId,
      operation: 'create',
      payload: {
        'guideId': guideId,
        'userId': userId,
        'content': content,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );

    // Attempt immediate sync
    await _syncCommentToFirestore(commentId);

    return (await getComment(commentId))!;
  }

  /// Update a comment.
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    final now = DateTime.now();

    await (_db.update(
      _db.guideComments,
    )..where((c) => c.id.equals(commentId))).write(
      GuideCommentsCompanion(
        content: drift.Value(content),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Comment updated locally: $commentId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_comments',
      recordId: commentId,
      operation: 'update',
      payload: {'content': content, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncCommentToFirestore(commentId);
  }

  /// Delete a comment (soft delete).
  Future<void> deleteComment(String commentId) async {
    final now = DateTime.now();

    await (_db.update(
      _db.guideComments,
    )..where((c) => c.id.equals(commentId))).write(
      GuideCommentsCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Comment deleted (soft): $commentId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_comments',
      recordId: commentId,
      operation: 'delete',
      payload: {'isDeleted': true, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncCommentToFirestore(commentId);
  }

  /// Get a single comment by ID.
  Future<GuideComment?> getComment(String commentId) async {
    return await (_db.select(_db.guideComments)
          ..where((c) => c.id.equals(commentId) & c.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all comments for a guide.
  Future<List<GuideComment>> getGuideComments(String guideId) async {
    return await (_db.select(_db.guideComments)
          ..where((c) => c.guideId.equals(guideId) & c.isDeleted.equals(false))
          ..orderBy([(c) => drift.OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Watch all comments for a guide.
  Stream<List<GuideComment>> watchGuideComments(String guideId) {
    return (_db.select(_db.guideComments)
          ..where((c) => c.guideId.equals(guideId) & c.isDeleted.equals(false))
          ..orderBy([(c) => drift.OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  /// Get comment count for a guide.
  Future<int> getCommentCount(String guideId) async {
    return await (_db.select(_db.guideComments)
          ..where((c) => c.guideId.equals(guideId) & c.isDeleted.equals(false)))
        .get()
        .then((comments) => comments.length);
  }

  // ==================== SYNC ====================

  /// Sync like to Firestore.
  Future<void> _syncLikeToFirestore(String guideId, String userId) async {
    try {
      final docRef = _firestore.collection('guide_likes').doc();
      await docRef.set({
        'guideId': guideId,
        'userId': userId,
        'likedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.talker.info('Like synced to Firestore: $guideId');

      // Update lastSyncedAt
      await (_db.update(_db.guideLikes)
            ..where((l) => l.guideId.equals(guideId) & l.userId.equals(userId)))
          .write(
            GuideLikesCompanion(lastSyncedAt: drift.Value(DateTime.now())),
          );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync like to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Sync comment to Firestore.
  Future<void> _syncCommentToFirestore(String commentId) async {
    try {
      final comment = await getComment(commentId);
      if (comment == null) {
        AppLogger.talker.warning('Comment not found for sync: $commentId');
        return;
      }

      final docRef = _firestore.collection('guide_comments').doc(commentId);
      final data = {
        'guideId': comment.guideId,
        'userId': comment.userId,
        'content': comment.content,
        'createdAt': Timestamp.fromDate(comment.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': comment.isDeleted,
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Comment synced to Firestore: $commentId');

      // Update lastSyncedAt
      await (_db.update(
        _db.guideComments,
      )..where((c) => c.id.equals(commentId))).write(
        GuideCommentsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync comment to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Queue a sync operation.
  Future<void> _queueSync({
    required String targetTable,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            targetTable: targetTable,
            recordId: recordId,
            operation: operation,
            payload: jsonEncode(payload),
            createdAt: DateTime.now(),
          ),
        );
    AppLogger.talker.debug('Sync queued: $operation $targetTable/$recordId');
  }
}
