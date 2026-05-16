import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';

part 'trip_repository.g.dart';

/// Repository for trip data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.
@riverpod
TripRepository tripRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TripRepository(db, FirebaseFirestore.instance);
}

class TripRepository {
  TripRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Create a new trip.
  Future<Trip> createTrip({
    required String ownerId,
    required String title,
    required String description,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    String status = 'upcoming',
  }) async {
    final now = DateTime.now();
    final tripId = _firestore.collection('trips').doc().id;

    final companion = TripsCompanion.insert(
      id: tripId,
      ownerId: ownerId,
      title: title,
      description: drift.Value(description),
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      coverImageUrl: drift.Value(coverImageUrl),
      status: drift.Value(status),
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: const drift.Value.absent(),
      isDeleted: const drift.Value(false),
    );

    await _db.into(_db.trips).insert(companion);
    AppLogger.talker.info('Trip created locally: $tripId');

    // Queue for sync
    await _queueSync(
      targetTable: 'trips',
      recordId: tripId,
      operation: 'create',
      payload: _tripToMap(companion),
    );

    // Attempt immediate sync
    await _syncTripToFirestore(tripId);

    return (await getTrip(tripId))!;
  }

  /// Update an existing trip.
  Future<void> updateTrip({
    required String tripId,
    String? title,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? latitude,
    double? longitude,
    String? coverImageUrl,
    String? status,
  }) async {
    final now = DateTime.now();

    final companion = TripsCompanion(
      title: title != null ? drift.Value(title) : const drift.Value.absent(),
      description: description != null
          ? drift.Value(description)
          : const drift.Value.absent(),
      destination: destination != null
          ? drift.Value(destination)
          : const drift.Value.absent(),
      startDate: startDate != null
          ? drift.Value(startDate)
          : const drift.Value.absent(),
      endDate: endDate != null
          ? drift.Value(endDate)
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
      status: status != null ? drift.Value(status) : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(
      _db.trips,
    )..where((t) => t.id.equals(tripId))).write(companion);
    AppLogger.talker.info('Trip updated locally: $tripId');

    // Queue for sync
    await _queueSync(
      targetTable: 'trips',
      recordId: tripId,
      operation: 'update',
      payload: _tripToMap(companion),
    );

    // Attempt immediate sync
    await _syncTripToFirestore(tripId);
  }

  /// Update trip status.
  Future<void> updateTripStatus(String tripId, String status) async {
    final now = DateTime.now();

    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(status: drift.Value(status), updatedAt: drift.Value(now)),
    );

    AppLogger.talker.info('Trip status updated: $tripId -> $status');

    // Queue for sync
    await _queueSync(
      targetTable: 'trips',
      recordId: tripId,
      operation: 'update',
      payload: {'status': status, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncTripToFirestore(tripId);
  }

  /// Soft delete a trip.
  Future<void> deleteTrip(String tripId) async {
    final now = DateTime.now();

    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        isDeleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('Trip deleted (soft): $tripId');

    // Queue for sync
    await _queueSync(
      targetTable: 'trips',
      recordId: tripId,
      operation: 'delete',
      payload: {'isDeleted': true, 'updatedAt': now.toIso8601String()},
    );

    // Attempt immediate sync
    await _syncTripToFirestore(tripId);
  }

  /// Get a single trip by ID from local DB.
  Future<Trip?> getTrip(String tripId) async {
    return await (_db.select(_db.trips)
          ..where((t) => t.id.equals(tripId) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Watch a single trip by ID.
  Stream<Trip?> watchTrip(String tripId) {
    return (_db.select(_db.trips)
          ..where((t) => t.id.equals(tripId) & t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  /// Get all trips by owner.
  Future<List<Trip>> getMyTrips(String ownerId) async {
    return await (_db.select(_db.trips)
          ..where((t) => t.ownerId.equals(ownerId) & t.isDeleted.equals(false))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startDate)]))
        .get();
  }

  /// Watch all trips by owner.
  Stream<List<Trip>> watchMyTrips(String ownerId) {
    return (_db.select(_db.trips)
          ..where((t) => t.ownerId.equals(ownerId) & t.isDeleted.equals(false))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  /// Get upcoming trips (status = upcoming or ongoing).
  Future<List<Trip>> getUpcomingTrips(String ownerId) async {
    return await (_db.select(_db.trips)
          ..where(
            (t) =>
                t.ownerId.equals(ownerId) &
                t.isDeleted.equals(false) &
                (t.status.equals('upcoming') | t.status.equals('ongoing')),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.startDate)]))
        .get();
  }

  /// Watch upcoming trips.
  Stream<List<Trip>> watchUpcomingTrips(String ownerId) {
    return (_db.select(_db.trips)
          ..where(
            (t) =>
                t.ownerId.equals(ownerId) &
                t.isDeleted.equals(false) &
                (t.status.equals('upcoming') | t.status.equals('ongoing')),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.startDate)]))
        .watch();
  }

  /// Get past trips (status = completed or cancelled).
  Future<List<Trip>> getPastTrips(String ownerId) async {
    return await (_db.select(_db.trips)
          ..where(
            (t) =>
                t.ownerId.equals(ownerId) &
                t.isDeleted.equals(false) &
                (t.status.equals('completed') | t.status.equals('cancelled')),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.endDate)]))
        .get();
  }

  /// Watch past trips.
  Stream<List<Trip>> watchPastTrips(String ownerId) {
    return (_db.select(_db.trips)
          ..where(
            (t) =>
                t.ownerId.equals(ownerId) &
                t.isDeleted.equals(false) &
                (t.status.equals('completed') | t.status.equals('cancelled')),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.endDate)]))
        .watch();
  }

  /// Watch all trips where the user is owner OR collaborator.
  /// Reactively updates when either trips or collaborators change.
  Stream<List<Trip>> watchAllUserTrips(String userId) {
    final collaborators$ = (_db.select(
      _db.tripCollaborators,
    )..where((c) => c.userId.equals(userId))).watch();

    return collaborators$.asyncMap((collaborators) {
      final tripIds = collaborators.map((c) => c.tripId).toList();
      return (_db.select(_db.trips)
            ..where(
              (t) =>
                  t.isDeleted.equals(false) &
                  (t.ownerId.equals(userId) | t.id.isIn(tripIds)),
            )
            ..orderBy([(t) => drift.OrderingTerm.desc(t.startDate)]))
          .get();
    });
  }

  /// Watch upcoming trips where the user is owner OR collaborator.
  Stream<List<Trip>> watchAllUpcomingTrips(String userId) {
    final collaborators$ = (_db.select(
      _db.tripCollaborators,
    )..where((c) => c.userId.equals(userId))).watch();

    return collaborators$.asyncMap((collaborators) {
      final tripIds = collaborators.map((c) => c.tripId).toList();
      return (_db.select(_db.trips)
            ..where(
              (t) =>
                  t.isDeleted.equals(false) &
                  (t.status.equals('upcoming') | t.status.equals('ongoing')) &
                  (t.ownerId.equals(userId) | t.id.isIn(tripIds)),
            )
            ..orderBy([(t) => drift.OrderingTerm.asc(t.startDate)]))
          .get();
    });
  }

  /// Watch past trips where the user is owner OR collaborator.
  Stream<List<Trip>> watchAllPastTrips(String userId) {
    final collaborators$ = (_db.select(
      _db.tripCollaborators,
    )..where((c) => c.userId.equals(userId))).watch();

    return collaborators$.asyncMap((collaborators) {
      final tripIds = collaborators.map((c) => c.tripId).toList();
      return (_db.select(_db.trips)
            ..where(
              (t) =>
                  t.isDeleted.equals(false) &
                  (t.status.equals('completed') |
                      t.status.equals('cancelled')) &
                  (t.ownerId.equals(userId) | t.id.isIn(tripIds)),
            )
            ..orderBy([(t) => drift.OrderingTerm.desc(t.endDate)]))
          .get();
    });
  }

  /// Search trips by title, description, or destination.
  Future<List<Trip>> searchTrips(String userId, String query) async {
    final lowerQuery = query.toLowerCase();

    // Get collaborator trip IDs
    final collaborators = await (_db.select(
      _db.tripCollaborators,
    )..where((c) => c.userId.equals(userId))).get();
    final collaboratorTripIds = collaborators.map((c) => c.tripId).toList();

    // Get trips where user is owner or collaborator
    final trips =
        await (_db.select(_db.trips)..where(
              (t) =>
                  t.isDeleted.equals(false) &
                  (t.ownerId.equals(userId) | t.id.isIn(collaboratorTripIds)),
            ))
            .get();

    // Filter in memory
    return trips.where((trip) {
      return trip.title.toLowerCase().contains(lowerQuery) ||
          (trip.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          trip.destination.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Sync trip to Firestore.
  Future<void> _syncTripToFirestore(String tripId) async {
    try {
      final trip = await getTrip(tripId);
      if (trip == null) {
        AppLogger.talker.warning('Trip not found for sync: $tripId');
        return;
      }

      final docRef = _firestore.collection('trips').doc(tripId);
      final data = {
        'ownerId': trip.ownerId,
        'title': trip.title,
        'description': trip.description,
        'destination': trip.destination,
        'startDate': Timestamp.fromDate(trip.startDate),
        'endDate': Timestamp.fromDate(trip.endDate),
        'latitude': trip.latitude,
        'longitude': trip.longitude,
        'coverImageUrl': trip.coverImageUrl,
        'status': trip.status,
        'createdAt': Timestamp.fromDate(trip.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': trip.isDeleted,
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Trip synced to Firestore: $tripId');

      // Update lastSyncedAt
      await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync trip to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Sync trip from Firestore to local DB.
  Future<Trip> syncTripFromFirestore(String tripId) async {
    final docRef = _firestore.collection('trips').doc(tripId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw DataException(
        errorType: DataErrorType.notFound,
        technicalDetails: 'Trip not found in Firestore: $tripId',
      );
    }

    final data = docSnapshot.data()!;
    final now = DateTime.now();

    final companion = TripsCompanion.insert(
      id: tripId,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      description: drift.Value(data['description'] as String?),
      destination: data['destination'] as String,
      startDate: _parseTimestamp(data['startDate']) ?? now,
      endDate: _parseTimestamp(data['endDate']) ?? now,
      latitude: drift.Value(data['latitude'] as double?),
      longitude: drift.Value(data['longitude'] as double?),
      coverImageUrl: drift.Value(data['coverImageUrl'] as String?),
      status: drift.Value(data['status'] as String? ?? 'upcoming'),
      createdAt: _parseTimestamp(data['createdAt']) ?? now,
      updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
      lastSyncedAt: drift.Value(now),
      isDeleted: drift.Value(data['isDeleted'] as bool? ?? false),
    );

    await _db
        .into(_db.trips)
        .insert(companion, mode: drift.InsertMode.insertOrReplace);

    AppLogger.talker.info('Trip synced from Firestore: $tripId');
    return (await getTrip(tripId))!;
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

  /// Convert trip companion to map for sync.
  Map<String, dynamic> _tripToMap(TripsCompanion companion) {
    return {
      // Always include ownerId — Firestore security rules require it for
      // create authorization even when only partial fields changed.
      if (companion.ownerId.present) 'ownerId': companion.ownerId.value,
      if (companion.title.present) 'title': companion.title.value,
      if (companion.description.present)
        'description': companion.description.value,
      if (companion.destination.present)
        'destination': companion.destination.value,
      if (companion.startDate.present)
        'startDate': companion.startDate.value.toIso8601String(),
      if (companion.endDate.present)
        'endDate': companion.endDate.value.toIso8601String(),
      if (companion.latitude.present) 'latitude': companion.latitude.value,
      if (companion.longitude.present) 'longitude': companion.longitude.value,
      if (companion.coverImageUrl.present)
        'coverImageUrl': companion.coverImageUrl.value,
      if (companion.status.present) 'status': companion.status.value,
      if (companion.createdAt.present)
        'createdAt': companion.createdAt.value.toIso8601String(),
      if (companion.updatedAt.present)
        'updatedAt': companion.updatedAt.value.toIso8601String(),
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
