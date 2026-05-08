import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';

part 'guide_itinerary_repository.g.dart';

/// Repository for guide itinerary items.
@riverpod
GuideItineraryRepository guideItineraryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return GuideItineraryRepository(db, FirebaseFirestore.instance);
}

class GuideItineraryRepository {
  GuideItineraryRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Add an itinerary item to a guide.
  Future<GuideItineraryItem> addItineraryItem({
    required String guideId,
    required String title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    required int dayNumber,
    DateTime? suggestedStartTime,
    DateTime? suggestedEndTime,
    String category = 'other',
    int sortOrder = 0,
    double? estimatedCost,
    String? costCurrency,
  }) async {
    final now = DateTime.now();
    final itemId = _firestore.collection('guide_itinerary_items').doc().id;

    final companion = GuideItineraryItemsCompanion.insert(
      id: itemId,
      guideId: guideId,
      title: title,
      description: drift.Value(description),
      locationName: drift.Value(locationName),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      dayNumber: dayNumber,
      suggestedStartTime: drift.Value(suggestedStartTime),
      suggestedEndTime: drift.Value(suggestedEndTime),
      category: drift.Value(category),
      sortOrder: drift.Value(sortOrder),
      estimatedCost: drift.Value(estimatedCost),
      costCurrency: drift.Value(costCurrency),
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.guideItineraryItems).insert(companion);
    AppLogger.talker.info('Itinerary item added locally: $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_itinerary_items',
      recordId: itemId,
      operation: 'create',
      payload: _itemToMap(companion),
    );

    // Attempt immediate sync
    await _syncItemToFirestore(itemId);

    return (await getItineraryItem(itemId))!;
  }

  /// Update an itinerary item.
  Future<void> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    int? dayNumber,
    DateTime? suggestedStartTime,
    DateTime? suggestedEndTime,
    String? category,
    int? sortOrder,
    double? estimatedCost,
    String? costCurrency,
  }) async {
    final now = DateTime.now();

    final companion = GuideItineraryItemsCompanion(
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      description: description != null
          ? drift.Value(description)
          : const drift.Value.absent(),
      locationName: locationName != null
          ? drift.Value(locationName)
          : const drift.Value.absent(),
      latitude:
          latitude != null ? drift.Value(latitude) : const drift.Value.absent(),
      longitude: longitude != null
          ? drift.Value(longitude)
          : const drift.Value.absent(),
      dayNumber: dayNumber != null
          ? drift.Value(dayNumber)
          : const drift.Value.absent(),
      suggestedStartTime: suggestedStartTime != null
          ? drift.Value(suggestedStartTime)
          : const drift.Value.absent(),
      suggestedEndTime: suggestedEndTime != null
          ? drift.Value(suggestedEndTime)
          : const drift.Value.absent(),
      category:
          category != null ? drift.Value(category) : const drift.Value.absent(),
      sortOrder: sortOrder != null
          ? drift.Value(sortOrder)
          : const drift.Value.absent(),
      estimatedCost: estimatedCost != null
          ? drift.Value(estimatedCost)
          : const drift.Value.absent(),
      costCurrency: costCurrency != null
          ? drift.Value(costCurrency)
          : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.guideItineraryItems)
          ..where((i) => i.id.equals(itemId)))
        .write(companion);
    AppLogger.talker.info('Itinerary item updated locally: $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_itinerary_items',
      recordId: itemId,
      operation: 'update',
      payload: _itemToMap(companion),
    );

    // Attempt immediate sync
    await _syncItemToFirestore(itemId);
  }

  /// Delete an itinerary item (soft delete).
  Future<void> deleteItineraryItem(String itemId) async {
    final now = DateTime.now();

    await (_db.update(_db.guideItineraryItems)
          ..where((i) => i.id.equals(itemId)))
        .write(
      GuideItineraryItemsCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Itinerary item deleted (soft): $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'guide_itinerary_items',
      recordId: itemId,
      operation: 'delete',
      payload: {
        'isDeleted': true,
        'updatedAt': now.toIso8601String(),
      },
    );

    // Attempt immediate sync
    await _syncItemToFirestore(itemId);
  }

  /// Get a single itinerary item by ID.
  Future<GuideItineraryItem?> getItineraryItem(String itemId) async {
    return await (_db.select(_db.guideItineraryItems)
          ..where((i) => i.id.equals(itemId) & i.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all itinerary items for a guide.
  Future<List<GuideItineraryItem>> getGuideItinerary(String guideId) async {
    return await (_db.select(_db.guideItineraryItems)
          ..where((i) => i.guideId.equals(guideId) & i.isDeleted.equals(false))
          ..orderBy([
            (i) => drift.OrderingTerm.asc(i.dayNumber),
            (i) => drift.OrderingTerm.asc(i.sortOrder),
          ]))
        .get();
  }

  /// Watch all itinerary items for a guide.
  Stream<List<GuideItineraryItem>> watchGuideItinerary(String guideId) {
    return (_db.select(_db.guideItineraryItems)
          ..where((i) => i.guideId.equals(guideId) & i.isDeleted.equals(false))
          ..orderBy([
            (i) => drift.OrderingTerm.asc(i.dayNumber),
            (i) => drift.OrderingTerm.asc(i.sortOrder),
          ]))
        .watch();
  }

  /// Reorder itinerary items within a day.
  Future<void> reorderItems(
    String guideId,
    int dayNumber,
    List<String> itemIds,
  ) async {
    for (var i = 0; i < itemIds.length; i++) {
      await updateItineraryItem(
        itemId: itemIds[i],
        sortOrder: i,
      );
    }

    AppLogger.talker.info(
      'Reordered ${itemIds.length} items for guide $guideId day $dayNumber',
    );
  }

  /// Get total estimated cost for a guide's itinerary.
  Future<Map<String, double>> getTotalEstimatedCost(String guideId) async {
    final items = await getGuideItinerary(guideId);
    final costByCurrency = <String, double>{};

    for (final item in items) {
      if (item.estimatedCost != null && item.costCurrency != null) {
        costByCurrency[item.costCurrency!] =
            (costByCurrency[item.costCurrency!] ?? 0) + item.estimatedCost!;
      }
    }

    return costByCurrency;
  }

  /// Sync itinerary item to Firestore.
  Future<void> _syncItemToFirestore(String itemId) async {
    try {
      final item = await getItineraryItem(itemId);
      if (item == null) {
        AppLogger.talker.warning('Itinerary item not found for sync: $itemId');
        return;
      }

      final docRef =
          _firestore.collection('guide_itinerary_items').doc(itemId);
      final data = {
        'guideId': item.guideId,
        'title': item.title,
        'description': item.description,
        'locationName': item.locationName,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'dayNumber': item.dayNumber,
        'suggestedStartTime': item.suggestedStartTime != null
            ? Timestamp.fromDate(item.suggestedStartTime!)
            : null,
        'suggestedEndTime': item.suggestedEndTime != null
            ? Timestamp.fromDate(item.suggestedEndTime!)
            : null,
        'category': item.category,
        'sortOrder': item.sortOrder,
        'estimatedCost': item.estimatedCost,
        'costCurrency': item.costCurrency,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': item.isDeleted,
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Itinerary item synced to Firestore: $itemId');

      // Update lastSyncedAt
      await (_db.update(_db.guideItineraryItems)
            ..where((i) => i.id.equals(itemId)))
          .write(
        GuideItineraryItemsCompanion(
          lastSyncedAt: drift.Value(DateTime.now()),
        ),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync itinerary item to Firestore (will retry later)',
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
    await _db.into(_db.syncQueue).insert(
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

  /// Convert itinerary item companion to map for sync.
  Map<String, dynamic> _itemToMap(GuideItineraryItemsCompanion companion) {
    return {
      if (companion.guideId.present) 'guideId': companion.guideId.value,
      if (companion.title.present) 'title': companion.title.value,
      if (companion.description.present)
        'description': companion.description.value,
      if (companion.locationName.present)
        'locationName': companion.locationName.value,
      if (companion.latitude.present) 'latitude': companion.latitude.value,
      if (companion.longitude.present) 'longitude': companion.longitude.value,
      if (companion.dayNumber.present) 'dayNumber': companion.dayNumber.value,
      if (companion.suggestedStartTime.present &&
          companion.suggestedStartTime.value != null)
        'suggestedStartTime':
            companion.suggestedStartTime.value!.toIso8601String(),
      if (companion.suggestedEndTime.present &&
          companion.suggestedEndTime.value != null)
        'suggestedEndTime':
            companion.suggestedEndTime.value!.toIso8601String(),
      if (companion.category.present) 'category': companion.category.value,
      if (companion.sortOrder.present) 'sortOrder': companion.sortOrder.value,
      if (companion.estimatedCost.present)
        'estimatedCost': companion.estimatedCost.value,
      if (companion.costCurrency.present)
        'costCurrency': companion.costCurrency.value,
      if (companion.createdAt.present)
        'createdAt': companion.createdAt.value.toIso8601String(),
      if (companion.updatedAt.present)
        'updatedAt': companion.updatedAt.value.toIso8601String(),
      if (companion.isDeleted.present) 'isDeleted': companion.isDeleted.value,
    };
  }
}
