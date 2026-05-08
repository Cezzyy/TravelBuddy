import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';

part 'guide_repository.g.dart';

/// Repository for guide data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.
@riverpod
GuideRepository guideRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return GuideRepository(db, FirebaseFirestore.instance);
}

class GuideRepository {
  GuideRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Create a new guide (draft by default).
  Future<Guide> createGuide({
    required String authorId,
    required String title,
    required String description,
    required String destination,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    String content = '',
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final guideId = _firestore.collection('guides').doc().id;

    final companion = GuidesCompanion.insert(
      id: guideId,
      authorId: authorId,
      title: title,
      description: description,
      destination: destination,
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      coverImageUrl: drift.Value(coverImageUrl),
      content: content,
      tags: drift.Value(tags != null ? jsonEncode(tags) : null),
      viewCount: const drift.Value(0),
      likeCount: const drift.Value(0),
      isPublished: const drift.Value(false),
      createdAt: now,
      updatedAt: now,
      publishedAt: const drift.Value.absent(),
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.guides).insert(companion);
    AppLogger.talker.info('Guide created locally: $guideId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'create',
      payload: _guideToMap(companion),
    );

    // Attempt immediate sync
    await _syncGuideToFirestore(guideId);

    return (await getGuide(guideId))!;
  }

  /// Update an existing guide.
  Future<void> updateGuide({
    required String guideId,
    String? title,
    String? description,
    String? destination,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    String? content,
    List<String>? tags,
  }) async {
    final now = DateTime.now();

    final companion = GuidesCompanion(
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      description: description != null
          ? drift.Value(description)
          : const drift.Value.absent(),
      destination: destination != null
          ? drift.Value(destination)
          : const drift.Value.absent(),
      latitude: latitude != null
          ? drift.Value(latitude)
          : const drift.Value.absent(),
      longitude: longitude != null
          ? drift.Value(longitude)
          : const drift.Value.absent(),
      coverImageUrl: coverImageUrl != null
          ? drift.Value(coverImageUrl)
          : const drift.Value.absent(),
      content: content != null
          ? drift.Value(content)
          : const drift.Value.absent(),
      tags: tags != null
          ? drift.Value(jsonEncode(tags))
          : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(
      _db.guides,
    )..where((g) => g.id.equals(guideId))).write(companion);
    AppLogger.talker.info('Guide updated locally: $guideId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'update',
      payload: _guideToMap(companion),
    );

    // Attempt immediate sync
    await _syncGuideToFirestore(guideId);
  }

  /// Publish a guide (make it public).
  Future<void> publishGuide(String guideId) async {
    final now = DateTime.now();

    await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
      GuidesCompanion(
        isPublished: const drift.Value(true),
        publishedAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Guide published: $guideId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'update',
      payload: {
        'isPublished': true,
        'publishedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );

    // Attempt immediate sync
    await _syncGuideToFirestore(guideId);
  }

  /// Unpublish a guide (make it draft).
  Future<void> unpublishGuide(String guideId) async {
    final now = DateTime.now();

    await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
      GuidesCompanion(
        isPublished: const drift.Value(false),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Guide unpublished: $guideId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'update',
      payload: {'isPublished': false, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncGuideToFirestore(guideId);
  }

  /// Soft delete a guide.
  Future<void> deleteGuide(String guideId) async {
    final now = DateTime.now();

    await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
      GuidesCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Guide deleted (soft): $guideId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'delete',
      payload: {'isDeleted': true, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncGuideToFirestore(guideId);
  }

  /// Get a single guide by ID from local DB.
  Future<Guide?> getGuide(String guideId) async {
    return await (_db.select(_db.guides)
          ..where((g) => g.id.equals(guideId) & g.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Watch a single guide by ID.
  Stream<Guide?> watchGuide(String guideId) {
    return (_db.select(_db.guides)
          ..where((g) => g.id.equals(guideId) & g.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  /// Get all guides by a specific author.
  Future<List<Guide>> getMyGuides(String authorId) async {
    return await (_db.select(_db.guides)
          ..where(
            (g) => g.authorId.equals(authorId) & g.isDeleted.equals(false),
          )
          ..orderBy([(g) => drift.OrderingTerm.desc(g.updatedAt)]))
        .get();
  }

  /// Watch all guides by a specific author.
  Stream<List<Guide>> watchMyGuides(String authorId) {
    return (_db.select(_db.guides)
          ..where(
            (g) => g.authorId.equals(authorId) & g.isDeleted.equals(false),
          )
          ..orderBy([(g) => drift.OrderingTerm.desc(g.updatedAt)]))
        .watch();
  }

  /// Get published guides (for discovery).
  Future<List<Guide>> getPublishedGuides({
    int limit = 50,
    int offset = 0,
  }) async {
    return await (_db.select(_db.guides)
          ..where((g) => g.isPublished.equals(true) & g.isDeleted.equals(false))
          ..orderBy([(g) => drift.OrderingTerm.desc(g.publishedAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Watch published guides.
  Stream<List<Guide>> watchPublishedGuides({int limit = 50}) {
    return (_db.select(_db.guides)
          ..where((g) => g.isPublished.equals(true) & g.isDeleted.equals(false))
          ..orderBy([(g) => drift.OrderingTerm.desc(g.publishedAt)])
          ..limit(limit))
        .watch();
  }

  /// Search guides by title, description, or destination.
  Future<List<Guide>> searchGuides(String query, {List<String>? tags}) async {
    final lowerQuery = query.toLowerCase();

    // Get all published guides
    final guides =
        await (_db.select(_db.guides)..where(
              (g) => g.isPublished.equals(true) & g.isDeleted.equals(false),
            ))
            .get();

    // Filter in memory (Drift doesn't support full-text search)
    return guides.where((guide) {
      final matchesText =
          guide.title.toLowerCase().contains(lowerQuery) ||
          guide.description.toLowerCase().contains(lowerQuery) ||
          guide.destination.toLowerCase().contains(lowerQuery);

      if (tags != null && tags.isNotEmpty) {
        final guideTags = guide.tags != null
            ? List<String>.from(jsonDecode(guide.tags!))
            : <String>[];
        final matchesTags = tags.any(
          (tag) => guideTags.contains(tag.toLowerCase()),
        );
        return matchesText && matchesTags;
      }

      return matchesText;
    }).toList();
  }

  /// Increment view count for a guide.
  Future<void> incrementViewCount(String guideId) async {
    final guide = await getGuide(guideId);
    if (guide == null) return;

    final newCount = guide.viewCount + 1;

    await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
      GuidesCompanion(viewCount: drift.Value(newCount)),
    );

    // Queue for sync (low priority, don't need immediate sync)
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'update',
      payload: {'viewCount': newCount},
    );
  }

  /// Update like count for a guide.
  Future<void> updateLikeCount(String guideId, int delta) async {
    final guide = await getGuide(guideId);
    if (guide == null) return;

    final newCount = (guide.likeCount + delta)
        .clamp(0, double.infinity)
        .toInt();

    await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
      GuidesCompanion(likeCount: drift.Value(newCount)),
    );

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: guideId,
      operation: 'update',
      payload: {'likeCount': newCount},
    );
  }

  /// Create a draft version of a published guide for editing.
  /// Returns the draft guide ID.
  Future<String> createDraftVersion(String publishedGuideId) async {
    final publishedGuide = await getGuide(publishedGuideId);
    if (publishedGuide == null) {
      throw Exception('Published guide not found: $publishedGuideId');
    }

    // Check if draft already exists
    if (publishedGuide.draftVersionId != null) {
      return publishedGuide.draftVersionId!;
    }

    final now = DateTime.now();
    final draftId = _firestore.collection('guides').doc().id;

    // Create draft guide with same content
    final draftCompanion = GuidesCompanion.insert(
      id: draftId,
      authorId: publishedGuide.authorId,
      title: publishedGuide.title,
      description: publishedGuide.description,
      destination: publishedGuide.destination,
      latitude: drift.Value(publishedGuide.latitude),
      longitude: drift.Value(publishedGuide.longitude),
      coverImageUrl: drift.Value(publishedGuide.coverImageUrl),
      content: publishedGuide.content,
      tags: drift.Value(publishedGuide.tags),
      viewCount: const drift.Value(0),
      likeCount: const drift.Value(0),
      isPublished: const drift.Value(false),
      publishedVersionId: drift.Value(publishedGuideId), // Link to published
      createdAt: now,
      updatedAt: now,
      publishedAt: const drift.Value.absent(),
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.guides).insert(draftCompanion);

    // Update published guide to reference the draft
    await (_db.update(
      _db.guides,
    )..where((g) => g.id.equals(publishedGuideId))).write(
      GuidesCompanion(
        draftVersionId: drift.Value(draftId),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info(
      'Draft version created: $draftId for $publishedGuideId',
    );

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: draftId,
      operation: 'create',
      payload: _guideToMap(draftCompanion),
    );

    return draftId;
  }

  /// Apply draft changes to the published guide.
  Future<void> applyDraftToPublished(String draftId) async {
    final draft = await getGuide(draftId);
    if (draft == null || draft.publishedVersionId == null) {
      throw Exception('Draft not found or not linked to published guide');
    }

    final publishedId = draft.publishedVersionId!;
    final now = DateTime.now();

    // Update published guide with draft content
    await (_db.update(
      _db.guides,
    )..where((g) => g.id.equals(publishedId))).write(
      GuidesCompanion(
        title: drift.Value(draft.title),
        description: drift.Value(draft.description),
        destination: drift.Value(draft.destination),
        latitude: drift.Value(draft.latitude),
        longitude: drift.Value(draft.longitude),
        coverImageUrl: drift.Value(draft.coverImageUrl),
        content: drift.Value(draft.content),
        tags: drift.Value(draft.tags),
        updatedAt: drift.Value(now),
        draftVersionId: const drift.Value.absent(), // Clear draft reference
      ),
    );

    // Delete the draft
    await (_db.update(_db.guides)..where((g) => g.id.equals(draftId))).write(
      GuidesCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info(
      'Draft applied to published: $draftId -> $publishedId',
    );

    // Queue for sync
    await _queueSync(
      targetTable: 'guides',
      recordId: publishedId,
      operation: 'update',
      payload: {
        'title': draft.title,
        'description': draft.description,
        'destination': draft.destination,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
        'coverImageUrl': draft.coverImageUrl,
        'content': draft.content,
        'tags': draft.tags,
        'updatedAt': now.toIso8601String(),
      },
    );

    await _syncGuideToFirestore(publishedId);
  }

  /// Discard draft changes (delete the draft version).
  Future<void> discardDraft(String draftId) async {
    final draft = await getGuide(draftId);
    if (draft == null || draft.publishedVersionId == null) {
      throw Exception('Draft not found or not linked to published guide');
    }

    final publishedId = draft.publishedVersionId!;
    final now = DateTime.now();

    // Clear draft reference from published guide
    await (_db.update(
      _db.guides,
    )..where((g) => g.id.equals(publishedId))).write(
      GuidesCompanion(
        draftVersionId: const drift.Value(null),
        updatedAt: drift.Value(now),
      ),
    );

    // Delete the draft
    await deleteGuide(draftId);

    AppLogger.talker.info('Draft discarded: $draftId');
  }

  /// Get the draft version of a published guide, if it exists.
  Future<Guide?> getDraftVersion(String publishedGuideId) async {
    final published = await getGuide(publishedGuideId);
    if (published == null || published.draftVersionId == null) {
      return null;
    }
    return await getGuide(published.draftVersionId!);
  }

  /// Get the published version of a draft guide, if it exists.
  Future<Guide?> getPublishedVersion(String draftId) async {
    final draft = await getGuide(draftId);
    if (draft == null || draft.publishedVersionId == null) {
      return null;
    }
    return await getGuide(draft.publishedVersionId!);
  }

  /// Sync guide to Firestore.
  Future<void> _syncGuideToFirestore(String guideId) async {
    try {
      final guide = await getGuide(guideId);
      if (guide == null) {
        AppLogger.talker.warning('Guide not found for sync: $guideId');
        return;
      }

      final docRef = _firestore.collection('guides').doc(guideId);
      final data = {
        'authorId': guide.authorId,
        'title': guide.title,
        'description': guide.description,
        'destination': guide.destination,
        'latitude': guide.latitude,
        'longitude': guide.longitude,
        'coverImageUrl': guide.coverImageUrl,
        'content': guide.content,
        'tags': guide.tags,
        'viewCount': guide.viewCount,
        'likeCount': guide.likeCount,
        'isPublished': guide.isPublished,
        'createdAt': Timestamp.fromDate(guide.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'publishedAt': guide.publishedAt != null
            ? Timestamp.fromDate(guide.publishedAt!)
            : null,
        'isDeleted': guide.isDeleted,
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Guide synced to Firestore: $guideId');

      // Update lastSyncedAt
      await (_db.update(_db.guides)..where((g) => g.id.equals(guideId))).write(
        GuidesCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync guide to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Sync guide from Firestore to local DB.
  Future<Guide> syncGuideFromFirestore(String guideId) async {
    final docRef = _firestore.collection('guides').doc(guideId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('Guide not found in Firestore: $guideId');
    }

    final data = docSnapshot.data()!;
    final now = DateTime.now();

    final companion = GuidesCompanion.insert(
      id: guideId,
      authorId: data['authorId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      destination: data['destination'] as String,
      latitude: drift.Value(data['latitude'] as double?),
      longitude: drift.Value(data['longitude'] as double?),
      coverImageUrl: drift.Value(data['coverImageUrl'] as String?),
      content: data['content'] as String? ?? '',
      tags: drift.Value(data['tags'] as String?),
      viewCount: drift.Value(data['viewCount'] as int? ?? 0),
      likeCount: drift.Value(data['likeCount'] as int? ?? 0),
      isPublished: drift.Value(data['isPublished'] as bool? ?? false),
      createdAt: _parseTimestamp(data['createdAt']) ?? now,
      updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
      publishedAt: drift.Value(_parseTimestamp(data['publishedAt'])),
      lastSyncedAt: drift.Value(now),
      isDeleted: drift.Value(data['isDeleted'] as bool? ?? false),
    );

    await _db
        .into(_db.guides)
        .insert(companion, mode: drift.InsertMode.insertOrReplace);

    AppLogger.talker.info('Guide synced from Firestore: $guideId');
    return (await getGuide(guideId))!;
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

  /// Convert guide companion to map for sync.
  Map<String, dynamic> _guideToMap(GuidesCompanion companion) {
    return {
      if (companion.title.present) 'title': companion.title.value,
      if (companion.description.present)
        'description': companion.description.value,
      if (companion.destination.present)
        'destination': companion.destination.value,
      if (companion.latitude.present) 'latitude': companion.latitude.value,
      if (companion.longitude.present) 'longitude': companion.longitude.value,
      if (companion.coverImageUrl.present)
        'coverImageUrl': companion.coverImageUrl.value,
      if (companion.content.present) 'content': companion.content.value,
      if (companion.tags.present) 'tags': companion.tags.value,
      if (companion.viewCount.present) 'viewCount': companion.viewCount.value,
      if (companion.likeCount.present) 'likeCount': companion.likeCount.value,
      if (companion.isPublished.present)
        'isPublished': companion.isPublished.value,
      if (companion.createdAt.present)
        'createdAt': companion.createdAt.value.toIso8601String(),
      if (companion.updatedAt.present)
        'updatedAt': companion.updatedAt.value.toIso8601String(),
      if (companion.publishedAt.present && companion.publishedAt.value != null)
        'publishedAt': companion.publishedAt.value!.toIso8601String(),
      if (companion.isDeleted.present) 'isDeleted': companion.isDeleted.value,
    };
  }

  /// Parse Firestore Timestamp to DateTime.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
