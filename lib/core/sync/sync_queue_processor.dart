import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/app_db.dart';
import '../../shared/data/providers/database_provider.dart';
import '../logging/app_logger.dart';

/// Processes pending items in the sync queue with retry logic and exponential backoff.
///
/// The sync queue stores local-first writes that failed to reach Firestore.
/// This processor:
/// 1. Reads all pending items from the local queue
/// 2. Attempts each write to Firestore
/// 3. On success: marks the item as completed and removes it
/// 4. On failure: increments retry count with exponential backoff
/// 5. Gives up after max retries
class SyncQueueProcessor {
  SyncQueueProcessor(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Maximum number of retries before giving up on a sync item.
  static const int maxRetries = 5;

  /// Base delay for exponential backoff (in seconds).
  static const int backoffBaseSeconds = 2;

  /// Whether a processing run is currently in progress.
  bool _isProcessing = false;

  /// Process all pending items in the sync queue.
  ///
  /// Returns the number of items successfully processed.
  /// Safe to call concurrently — will skip if already processing.
  Future<int> processPending() async {
    if (_isProcessing) {
      AppLogger.talker.debug('SyncQueue: Already processing, skipping');
      return 0;
    }

    _isProcessing = true;
    int processed = 0;

    try {
      final pendingItems = await _getPendingItems();

      if (pendingItems.isEmpty) {
        AppLogger.talker.debug('SyncQueue: No pending items');
        return 0;
      }

      AppLogger.talker.info(
        'SyncQueue: Processing ${pendingItems.length} pending items',
      );

      for (final item in pendingItems) {
        // Check if we've exceeded max retries
        if (item.retryCount >= maxRetries) {
          AppLogger.talker.warning(
            'SyncQueue: Item ${item.id} exceeded max retries ($maxRetries), '
            'marking as failed',
          );
          await _markAsFailed(item);
          continue;
        }

        // Check exponential backoff: skip if not enough time has passed
        if (!_isReadyForRetry(item)) {
          AppLogger.talker.debug(
            'SyncQueue: Item ${item.id} not ready for retry '
            '(attempt ${item.retryCount}), skipping',
          );
          continue;
        }

        final success = await _processItem(item);
        if (success) {
          processed++;
        }
      }
    } catch (e, st) {
      AppLogger.talker.error('SyncQueue: Error processing queue', e, st);
    } finally {
      _isProcessing = false;
    }

    if (processed > 0) {
      AppLogger.talker.info(
        'SyncQueue: Successfully processed $processed items',
      );
    }

    return processed;
  }

  /// Get all pending or in-progress items, ordered by creation time.
  Future<List<SyncQueueData>> _getPendingItems() async {
    return await (_db.select(_db.syncQueue)
          ..where(
            (t) => t.status.equals('pending') | t.status.equals('in_progress'),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Check if enough time has passed since the last attempt (exponential backoff).
  bool _isReadyForRetry(SyncQueueData item) {
    // First attempt is always ready
    if (item.retryCount == 0) return true;

    // Calculate backoff delay: 2^retryCount * base seconds
    final delaySeconds = (backoffBaseSeconds * (1 << item.retryCount)).clamp(
      1,
      300,
    );

    final earliestRetry = item.createdAt.add(
      Duration(seconds: delaySeconds * item.retryCount),
    );

    return DateTime.now().isAfter(earliestRetry);
  }

  /// Process a single sync queue item.
  Future<bool> _processItem(SyncQueueData item) async {
    // Mark as in_progress
    await _updateStatus(item, 'in_progress');

    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;

      switch (item.targetTable) {
        case 'users':
          await _syncUser(item, payload);
          break;
        case 'user_preferences':
          await _syncUserPreferences(item, payload);
          break;
        case 'trips':
          await _syncTrip(item, payload);
          break;
        case 'itinerary_items':
          await _syncItineraryItem(item, payload);
          break;
        case 'trip_invitations':
          // Invitations are synced directly in the repository
          await _removeFromQueue(item);
          return true;
        case 'trip_collaborators':
          // Collaborators are synced directly in the repository
          await _removeFromQueue(item);
          return true;
        case 'guides':
          await _syncGuide(item, payload);
          break;
        case 'guide_itinerary_items':
          await _syncGuideItineraryItem(item, payload);
          break;
        case 'guide_likes':
          await _syncGuideLike(item, payload);
          break;
        case 'guide_comments':
          await _syncGuideComment(item, payload);
          break;
        default:
          AppLogger.talker.warning(
            'SyncQueue: Unknown target table: ${item.targetTable}',
          );
          await _markAsFailed(item);
          return false;
      }

      // Success — remove from queue
      await _removeFromQueue(item);
      AppLogger.talker.info(
        'SyncQueue: Successfully synced ${item.operation} '
        '${item.targetTable}/${item.recordId}',
      );
      return true;
    } catch (e, st) {
      AppLogger.talker.warning(
        'SyncQueue: Failed to process ${item.operation} '
        '${item.targetTable}/${item.recordId} '
        '(attempt ${item.retryCount + 1}/$maxRetries)',
        e,
        st,
      );

      // Increment retry count
      await _incrementRetryCount(item);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Table-specific sync methods
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _syncUser(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('users').doc(item.recordId);
    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _syncUserPreferences(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('users').doc(item.recordId);
    await docRef.update({
      'preferences': payload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _syncTrip(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('trips').doc(item.recordId);

    if (item.operation == 'delete') {
      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Convert ISO strings back to Firestore-compatible format
      final data = _convertTimestamps(payload);
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Ensure ownerId is always present — Firestore security rules require
      // it for create authorization, and partial payloads from updates
      // may not include it.
      if (!data.containsKey('ownerId')) {
        final trip = await (_db.select(
          _db.trips,
        )..where((t) => t.id.equals(item.recordId))).getSingleOrNull();
        if (trip != null) {
          data['ownerId'] = trip.ownerId;
        }
      }

      await docRef.set(data, SetOptions(merge: true));
    }
  }

  Future<void> _syncItineraryItem(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('itinerary_items').doc(item.recordId);

    if (item.operation == 'delete') {
      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = _convertTimestamps(payload);
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Ensure tripId is always present — Firestore security rules require
      // it for authorization checks on itinerary items.
      if (!data.containsKey('tripId')) {
        final itineraryItem = await (_db.select(
          _db.itineraryItems,
        )..where((i) => i.id.equals(item.recordId))).getSingleOrNull();
        if (itineraryItem != null) {
          data['tripId'] = itineraryItem.tripId;
        }
      }

      await docRef.set(data, SetOptions(merge: true));
    }
  }

  Future<void> _syncGuide(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('guides').doc(item.recordId);

    if (item.operation == 'delete') {
      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = _convertTimestamps(payload);
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Ensure authorId is always present — Firestore security rules require
      // it for create/update authorization, and partial payloads from updates
      // may not include it.
      if (!data.containsKey('authorId')) {
        final guide = await (_db.select(
          _db.guides,
        )..where((g) => g.id.equals(item.recordId))).getSingleOrNull();
        if (guide != null) {
          data['authorId'] = guide.authorId;
        }
      }

      await docRef.set(data, SetOptions(merge: true));
    }
  }

  Future<void> _syncGuideItineraryItem(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore
        .collection('guide_itinerary_items')
        .doc(item.recordId);

    if (item.operation == 'delete') {
      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = _convertTimestamps(payload);
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Ensure guideId is always present — Firestore security rules require
      // it for create authorization via isGuideAuthor().
      if (!data.containsKey('guideId')) {
        final itineraryItem = await (_db.select(
          _db.guideItineraryItems,
        )..where((i) => i.id.equals(item.recordId))).getSingleOrNull();
        if (itineraryItem != null) {
          data['guideId'] = itineraryItem.guideId;
        }
      }

      await docRef.set(data, SetOptions(merge: true));
    }
  }

  Future<void> _syncGuideLike(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    if (item.operation == 'delete') {
      // Delete likes by query
      final snapshot = await _firestore
          .collection('guide_likes')
          .where('guideId', isEqualTo: payload['guideId'])
          .where('userId', isEqualTo: payload['userId'])
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      // Create like — use a deterministic ID for idempotency
      final docId = '${payload['guideId']}_${payload['userId']}';
      await _firestore.collection('guide_likes').doc(docId).set({
        'guideId': payload['guideId'],
        'userId': payload['userId'],
        'likedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _syncGuideComment(
    SyncQueueData item,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore.collection('guide_comments').doc(item.recordId);

    if (item.operation == 'delete') {
      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = _convertTimestamps(payload);
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data, SetOptions(merge: true));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Queue management helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updateStatus(SyncQueueData item, String status) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
      SyncQueueCompanion(status: drift.Value(status)),
    );
  }

  Future<void> _markAsFailed(SyncQueueData item) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
      SyncQueueCompanion(status: const drift.Value('failed')),
    );
  }

  Future<void> _incrementRetryCount(SyncQueueData item) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
      SyncQueueCompanion(
        retryCount: drift.Value(item.retryCount + 1),
        status: const drift.Value('pending'), // Reset to pending for retry
      ),
    );
  }

  Future<void> _removeFromQueue(SyncQueueData item) async {
    await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
  }

  /// Convert ISO timestamp strings back to a format Firestore can handle.
  /// The sync queue stores timestamps as ISO strings; Firestore expects
  /// either Timestamp objects or server timestamps.
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> payload) {
    final result = <String, dynamic>{};
    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        // Try to parse as ISO timestamp for known date fields
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('at') || lowerKey.contains('date')) {
          try {
            final dt = DateTime.parse(value);
            result[key] = Timestamp.fromDate(dt);
            continue;
          } catch (_) {
            // Not a valid date string, keep as-is
          }
        }
      }

      result[key] = value;
    }
    return result;
  }

  /// Clean up completed and old failed items from the queue.
  Future<void> cleanup({Duration? olderThan}) async {
    final cutoff = DateTime.now().subtract(
      olderThan ?? const Duration(days: 7),
    );

    // Remove completed items older than cutoff
    await (_db.delete(_db.syncQueue)..where(
          (t) =>
              t.status.equals('completed') &
              t.createdAt.isSmallerThanValue(cutoff),
        ))
        .go();

    // Remove failed items older than cutoff
    await (_db.delete(_db.syncQueue)..where(
          (t) =>
              t.status.equals('failed') &
              t.createdAt.isSmallerThanValue(cutoff),
        ))
        .go();

    AppLogger.talker.info('SyncQueue: Cleanup completed');
  }
}

/// Riverpod provider for SyncQueueProcessor.
final syncQueueProcessorProvider = Provider<SyncQueueProcessor>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueueProcessor(db, FirebaseFirestore.instance);
});
