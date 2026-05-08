import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';

part 'trip_itinerary_repository.g.dart';

/// Repository for trip itinerary items.
@riverpod
TripItineraryRepository tripItineraryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TripItineraryRepository(db, FirebaseFirestore.instance);
}

class TripItineraryRepository {
  TripItineraryRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Add an itinerary item to a trip.
  Future<ItineraryItem> addItineraryItem({
    required String tripId,
    required String createdBy,
    required String title,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    String category = 'other',
    int sortOrder = 0,
  }) async {
    final now = DateTime.now();
    final itemId = _firestore.collection('itinerary_items').doc().id;

    final companion = ItineraryItemsCompanion.insert(
      id: itemId,
      tripId: tripId,
      createdBy: createdBy,
      title: title,
      description: drift.Value(description),
      locationName: drift.Value(locationName),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      scheduledDate: scheduledDate,
      startTime: drift.Value(startTime),
      endTime: drift.Value(endTime),
      category: drift.Value(category),
      sortOrder: drift.Value(sortOrder),
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.itineraryItems).insert(companion);
    AppLogger.talker.info('Itinerary item added locally: $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'itinerary_items',
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
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    int? sortOrder,
  }) async {
    final now = DateTime.now();

    final companion = ItineraryItemsCompanion(
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      description: description != null
          ? drift.Value(description)
          : const drift.Value.absent(),
      locationName: locationName != null
          ? drift.Value(locationName)
          : const drift.Value.absent(),
      latitude: latitude != null
          ? drift.Value(latitude)
          : const drift.Value.absent(),
      longitude: longitude != null
          ? drift.Value(longitude)
          : const drift.Value.absent(),
      scheduledDate: scheduledDate != null
          ? drift.Value(scheduledDate)
          : const drift.Value.absent(),
      startTime: startTime != null
          ? drift.Value(startTime)
          : const drift.Value.absent(),
      endTime: endTime != null
          ? drift.Value(endTime)
          : const drift.Value.absent(),
      category: category != null
          ? drift.Value(category)
          : const drift.Value.absent(),
      sortOrder: sortOrder != null
          ? drift.Value(sortOrder)
          : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(
      _db.itineraryItems,
    )..where((i) => i.id.equals(itemId))).write(companion);
    AppLogger.talker.info('Itinerary item updated locally: $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'itinerary_items',
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

    await (_db.update(
      _db.itineraryItems,
    )..where((i) => i.id.equals(itemId))).write(
      ItineraryItemsCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Itinerary item deleted (soft): $itemId');

    // Queue for sync
    await _queueSync(
      targetTable: 'itinerary_items',
      recordId: itemId,
      operation: 'delete',
      payload: {'isDeleted': true, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncItemToFirestore(itemId);
  }

  /// Get a single itinerary item by ID.
  Future<ItineraryItem?> getItineraryItem(String itemId) async {
    return await (_db.select(_db.itineraryItems)
          ..where((i) => i.id.equals(itemId) & i.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get all itinerary items for a trip.
  Future<List<ItineraryItem>> getTripItinerary(String tripId) async {
    return await (_db.select(_db.itineraryItems)
          ..where((i) => i.tripId.equals(tripId) & i.isDeleted.equals(false))
          ..orderBy([
            (i) => drift.OrderingTerm.asc(i.scheduledDate),
            (i) => drift.OrderingTerm.asc(i.sortOrder),
          ]))
        .get();
  }

  /// Watch all itinerary items for a trip.
  Stream<List<ItineraryItem>> watchTripItinerary(String tripId) {
    return (_db.select(_db.itineraryItems)
          ..where((i) => i.tripId.equals(tripId) & i.isDeleted.equals(false))
          ..orderBy([
            (i) => drift.OrderingTerm.asc(i.scheduledDate),
            (i) => drift.OrderingTerm.asc(i.sortOrder),
          ]))
        .watch();
  }

  /// Get itinerary items for a specific date.
  Future<List<ItineraryItem>> getItemsByDate(
    String tripId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (_db.select(_db.itineraryItems)
          ..where(
            (i) =>
                i.tripId.equals(tripId) &
                i.isDeleted.equals(false) &
                i.scheduledDate.isBiggerOrEqualValue(startOfDay) &
                i.scheduledDate.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(i) => drift.OrderingTerm.asc(i.sortOrder)]))
        .get();
  }

  /// Watch itinerary items for a specific date.
  Stream<List<ItineraryItem>> watchItemsByDate(String tripId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.itineraryItems)
          ..where(
            (i) =>
                i.tripId.equals(tripId) &
                i.isDeleted.equals(false) &
                i.scheduledDate.isBiggerOrEqualValue(startOfDay) &
                i.scheduledDate.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(i) => drift.OrderingTerm.asc(i.sortOrder)]))
        .watch();
  }

  /// Reorder itinerary items within a date.
  Future<void> reorderItems(
    String tripId,
    DateTime date,
    List<String> itemIds,
  ) async {
    for (var i = 0; i < itemIds.length; i++) {
      await updateItineraryItem(itemId: itemIds[i], sortOrder: i);
    }

    AppLogger.talker.info(
      'Reordered ${itemIds.length} items for trip $tripId on $date',
    );
  }

  /// Get items grouped by date.
  Future<Map<DateTime, List<ItineraryItem>>> getItemsGroupedByDate(
    String tripId,
  ) async {
    final items = await getTripItinerary(tripId);
    final grouped = <DateTime, List<ItineraryItem>>{};

    for (final item in items) {
      final dateKey = DateTime(
        item.scheduledDate.year,
        item.scheduledDate.month,
        item.scheduledDate.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    return grouped;
  }

  /// Sync itinerary item to Firestore.
  Future<void> _syncItemToFirestore(String itemId) async {
    try {
      final item = await getItineraryItem(itemId);
      if (item == null) {
        AppLogger.talker.warning('Itinerary item not found for sync: $itemId');
        return;
      }

      final docRef = _firestore.collection('itinerary_items').doc(itemId);
      final data = {
        'tripId': item.tripId,
        'createdBy': item.createdBy,
        'title': item.title,
        'description': item.description,
        'locationName': item.locationName,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'scheduledDate': Timestamp.fromDate(item.scheduledDate),
        'startTime': item.startTime != null
            ? Timestamp.fromDate(item.startTime!)
            : null,
        'endTime': item.endTime != null
            ? Timestamp.fromDate(item.endTime!)
            : null,
        'category': item.category,
        'sortOrder': item.sortOrder,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': item.isDeleted,
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Itinerary item synced to Firestore: $itemId');

      // Update lastSyncedAt
      await (_db.update(
        _db.itineraryItems,
      )..where((i) => i.id.equals(itemId))).write(
        ItineraryItemsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
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

  /// Convert itinerary item companion to map for sync.
  Map<String, dynamic> _itemToMap(ItineraryItemsCompanion companion) {
    return {
      if (companion.tripId.present) 'tripId': companion.tripId.value,
      if (companion.createdBy.present) 'createdBy': companion.createdBy.value,
      if (companion.title.present) 'title': companion.title.value,
      if (companion.description.present)
        'description': companion.description.value,
      if (companion.locationName.present)
        'locationName': companion.locationName.value,
      if (companion.latitude.present) 'latitude': companion.latitude.value,
      if (companion.longitude.present) 'longitude': companion.longitude.value,
      if (companion.scheduledDate.present)
        'scheduledDate': companion.scheduledDate.value.toIso8601String(),
      if (companion.startTime.present && companion.startTime.value != null)
        'startTime': companion.startTime.value!.toIso8601String(),
      if (companion.endTime.present && companion.endTime.value != null)
        'endTime': companion.endTime.value!.toIso8601String(),
      if (companion.category.present) 'category': companion.category.value,
      if (companion.sortOrder.present) 'sortOrder': companion.sortOrder.value,
      if (companion.createdAt.present)
        'createdAt': companion.createdAt.value.toIso8601String(),
      if (companion.updatedAt.present)
        'updatedAt': companion.updatedAt.value.toIso8601String(),
      if (companion.isDeleted.present) 'isDeleted': companion.isDeleted.value,
    };
  }
}
