import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/app_db.dart';
import '../../shared/data/providers/database_provider.dart';
import '../logging/app_logger.dart';
import '../notifications/local_notification_service.dart';

/// Manages real-time Firestore listeners that push remote changes into the
/// local Drift database.
///
/// The existing repository pattern already writes local → Firestore on every
/// mutation. This service handles the reverse direction: Firestore → local.
/// It watches remote collections that the authenticated user has access to
/// and upserts changed documents into Drift, keeping the local DB in sync
/// with collaborative edits from other users.
///
/// Lifecycle:
/// - Call [startListeners] when the user signs in.
/// - Call [stopListeners] when the user signs out.
/// - The service uses the Firebase Auth state to determine which data to
///   subscribe to.
class FirestoreSyncService {
  FirestoreSyncService(
    this._db,
    this._firestore,
    this._auth, {
    this.onNewInvitation,
  });

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

  /// Callback triggered when a new pending invitation is received from Firestore.
  /// Provides (invitationId, tripTitle, inviterName) for showing a local notification.
  final void Function(
    String invitationId,
    String tripTitle,
    String inviterName,
  )?
  onNewInvitation;

  /// Active Firestore subscription cancellations.
  final List<StreamSubscription<void>> _subscriptions = [];

  /// Whether listeners are currently active.
  bool _isListening = false;

  /// Start real-time listeners for the currently authenticated user.
  ///
  /// Subscribes to:
  /// 1. The user's own trips (owner or collaborator)
  /// 2. Itinerary items for those trips
  /// 3. Trip invitations targeting the user's email
  /// 4. Trip collaborators for those trips
  /// 5. The user's own guides
  /// 6. Guide itinerary items for those guides
  ///
  /// Safe to call multiple times; will not create duplicate subscriptions.
  void startListeners() {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.talker.warning(
        'FirestoreSync: No authenticated user, '
        'cannot start listeners',
      );
      return;
    }

    if (_isListening) {
      AppLogger.talker.debug('FirestoreSync: Listeners already active');
      return;
    }

    _isListening = true;
    AppLogger.talker.info('FirestoreSync: Starting listeners for ${user.uid}');

    _listenToTrips(user.uid);
    _listenToTripInvitations(user);
    _listenToGuides(user.uid);
  }

  /// Stop all real-time listeners and clean up resources.
  ///
  /// Call this when the user signs out to avoid leaking subscriptions
  /// and receiving data for the wrong user.
  void stopListeners() {
    if (!_isListening) return;

    AppLogger.talker.info('FirestoreSync: Stopping all listeners');
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _isListening = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Trip listeners
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToTrips(String userId) {
    // Listen to trips where the user is the owner
    final ownedTripsSub = _firestore
        .collection('trips')
        .where('ownerId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) => _handleTripsSnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to owned trips',
            e,
          ),
        );
    _subscriptions.add(ownedTripsSub);

    // Also listen to trips where the user is a collaborator
    // We need to first get the collaborator records, then listen to those trips
    final collaboratorSub = _firestore
        .collection('trip_collaborators')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleCollaboratorSnapshot(snapshot, userId),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to collaborators',
            e,
          ),
        );
    _subscriptions.add(collaboratorSub);
  }

  Future<void> _handleTripsSnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _upsertTripToLocal(change.doc.id, data);
          // Also start listening to itinerary items for this trip
          if (change.type == DocumentChangeType.added) {
            _listenToItineraryItems(change.doc.id);
          }
          break;
        case DocumentChangeType.removed:
          // Don't hard delete — soft deletes are handled by isDeleted flag
          break;
      }
    }
  }

  Future<void> _upsertTripToLocal(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
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
      AppLogger.talker.debug('FirestoreSync: Upserted trip $tripId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert trip $tripId',
        e,
        st,
      );
    }
  }

  Future<void> _handleCollaboratorSnapshot(
    QuerySnapshot snapshot,
    String userId,
  ) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          // Upsert the collaborator record locally
          await _upsertCollaboratorToLocal(change.doc.id, data);

          // When added as collaborator, also fetch the trip details
          if (change.type == DocumentChangeType.added) {
            final tripId = data['tripId'] as String;
            final tripDoc = await _firestore
                .collection('trips')
                .doc(tripId)
                .get();
            if (tripDoc.exists) {
              await _upsertTripToLocal(tripId, tripDoc.data()!);
              _listenToItineraryItems(tripId);
            }
          }
          break;
        case DocumentChangeType.removed:
          // Collaborator was removed — delete locally
          final tripId = data['tripId'] as String;
          await (_db.delete(_db.tripCollaborators)..where(
                (t) => t.tripId.equals(tripId) & t.userId.equals(userId),
              ))
              .go();
          AppLogger.talker.debug(
            'FirestoreSync: Removed collaborator for trip $tripId',
          );
          break;
      }
    }
  }

  Future<void> _upsertCollaboratorToLocal(
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final companion = TripCollaboratorsCompanion.insert(
        tripId: data['tripId'] as String,
        userId: data['userId'] as String,
        role: drift.Value(data['role'] as String? ?? 'viewer'),
        addedAt: _parseTimestamp(data['addedAt']) ?? now,
        lastSyncedAt: drift.Value(now),
      );

      await _db
          .into(_db.tripCollaborators)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);
      AppLogger.talker.debug('FirestoreSync: Upserted collaborator $docId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert collaborator $docId',
        e,
        st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Itinerary items listeners
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToItineraryItems(String tripId) {
    final sub = _firestore
        .collection('itinerary_items')
        .where('tripId', isEqualTo: tripId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) => _handleItinerarySnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to itinerary items for trip $tripId',
            e,
          ),
        );
    _subscriptions.add(sub);
  }

  Future<void> _handleItinerarySnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _upsertItineraryItemToLocal(change.doc.id, data);
          break;
        case DocumentChangeType.removed:
          // Soft-delete: mark isDeleted locally
          await (_db.update(
            _db.itineraryItems,
          )..where((i) => i.id.equals(change.doc.id))).write(
            ItineraryItemsCompanion(
              isDeleted: const drift.Value(true),
              lastSyncedAt: drift.Value(DateTime.now()),
            ),
          );
          break;
      }
    }
  }

  Future<void> _upsertItineraryItemToLocal(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final companion = ItineraryItemsCompanion.insert(
        id: itemId,
        tripId: data['tripId'] as String,
        createdBy: data['createdBy'] as String? ?? '',
        title: data['title'] as String,
        description: drift.Value(data['description'] as String?),
        locationName: drift.Value(data['locationName'] as String?),
        latitude: drift.Value(data['latitude'] as double?),
        longitude: drift.Value(data['longitude'] as double?),
        scheduledDate: _parseTimestamp(data['scheduledDate']) ?? now,
        startTime: drift.Value(_parseTimestamp(data['startTime'])),
        endTime: drift.Value(_parseTimestamp(data['endTime'])),
        category: drift.Value(data['category'] as String? ?? 'other'),
        sortOrder: drift.Value(data['sortOrder'] as int? ?? 0),
        createdAt: _parseTimestamp(data['createdAt']) ?? now,
        updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
        lastSyncedAt: drift.Value(now),
        isDeleted: drift.Value(data['isDeleted'] as bool? ?? false),
      );

      await _db
          .into(_db.itineraryItems)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);
      AppLogger.talker.debug('FirestoreSync: Upserted itinerary item $itemId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert itinerary item $itemId',
        e,
        st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Trip invitation listeners
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToTripInvitations(auth.User user) {
    // Listen to invitations targeting this user's email
    if (user.email == null) return;

    final email = user.email!;
    final sub = _firestore
        .collection('trip_invitations')
        .where('invitedEmail', isEqualTo: email)
        .snapshots()
        .listen(
          (snapshot) => _handleInvitationsSnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to invitations',
            e,
          ),
        );
    _subscriptions.add(sub);

    // Also listen to invitations created by this user (as trip owner)
    final ownerSub = _firestore
        .collection('trip_invitations')
        .where('invitedByUserId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) => _handleInvitationsSnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to owned invitations',
            e,
          ),
        );
    _subscriptions.add(ownerSub);
  }

  Future<void> _handleInvitationsSnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
          await _upsertInvitationToLocal(change.doc.id, data);
          _maybeNotifyNewInvitation(change.doc.id, data);
          break;
        case DocumentChangeType.modified:
          await _upsertInvitationToLocal(change.doc.id, data);
          break;
        case DocumentChangeType.removed:
          // Delete from local DB
          await (_db.delete(
            _db.tripInvitations,
          )..where((t) => t.id.equals(change.doc.id))).go();
          break;
      }
    }
  }

  /// Show a local notification only for new pending invitations
  /// that were sent by someone else (not our own invites).
  void _maybeNotifyNewInvitation(
    String invitationId,
    Map<String, dynamic> data,
  ) {
    if (onNewInvitation == null) return;

    final status = data['status'] as String? ?? '';
    if (status != 'pending') return;

    final invitedByUserId = data['invitedByUserId'] as String? ?? '';
    final currentUserId = _auth.currentUser?.uid;

    // Don't notify about invitations we sent ourselves
    if (currentUserId != null && invitedByUserId == currentUserId) return;

    final tripTitle = data['tripId'] as String? ?? 'a trip';
    final inviterName = data['invitedByUserId'] as String? ?? 'Someone';

    onNewInvitation!(invitationId, tripTitle, inviterName);
  }

  Future<void> _upsertInvitationToLocal(
    String invitationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final companion = TripInvitationsCompanion.insert(
        id: invitationId,
        tripId: data['tripId'] as String,
        invitedByUserId: data['invitedByUserId'] as String,
        invitedEmail: data['invitedEmail'] as String,
        invitedUserId: drift.Value(data['invitedUserId'] as String?),
        role: drift.Value(data['role'] as String? ?? 'viewer'),
        status: drift.Value(data['status'] as String? ?? 'pending'),
        createdAt: _parseTimestamp(data['createdAt']) ?? now,
        expiresAt: _parseTimestamp(data['expiresAt']) ?? now,
        respondedAt: drift.Value(_parseTimestamp(data['respondedAt'])),
        lastSyncedAt: drift.Value(now),
      );

      await _db
          .into(_db.tripInvitations)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);
      AppLogger.talker.debug(
        'FirestoreSync: Upserted invitation $invitationId',
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert invitation $invitationId',
        e,
        st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Guide listeners
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToGuides(String userId) {
    // Listen to guides authored by this user
    final ownedGuidesSub = _firestore
        .collection('guides')
        .where('authorId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) => _handleGuidesSnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to guides',
            e,
          ),
        );
    _subscriptions.add(ownedGuidesSub);

    // Listen to published guides (for discovery feed) — fetch initial batch
    // and then listen to changes. Use a limited query to avoid excessive reads.
    final publishedGuidesSub = _firestore
        .collection('guides')
        .where('isPublished', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) => _handleGuidesSnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to published guides',
            e,
          ),
        );
    _subscriptions.add(publishedGuidesSub);
  }

  Future<void> _handleGuidesSnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _upsertGuideToLocal(change.doc.id, data);
          // Start listening to itinerary items for this guide
          if (change.type == DocumentChangeType.added) {
            _listenToGuideItineraryItems(change.doc.id);
          }
          break;
        case DocumentChangeType.removed:
          // Soft-delete locally
          await (_db.update(
            _db.guides,
          )..where((g) => g.id.equals(change.doc.id))).write(
            GuidesCompanion(
              isDeleted: const drift.Value(true),
              lastSyncedAt: drift.Value(DateTime.now()),
            ),
          );
          break;
      }
    }
  }

  Future<void> _upsertGuideToLocal(
    String guideId,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final companion = GuidesCompanion.insert(
        id: guideId,
        authorId: data['authorId'] as String,
        title: data['title'] as String,
        description: data['description'] as String? ?? '',
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
      AppLogger.talker.debug('FirestoreSync: Upserted guide $guideId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert guide $guideId',
        e,
        st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Guide itinerary items listeners
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToGuideItineraryItems(String guideId) {
    final sub = _firestore
        .collection('guide_itinerary_items')
        .where('guideId', isEqualTo: guideId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) => _handleGuideItinerarySnapshot(snapshot),
          onError: (e) => AppLogger.talker.warning(
            'FirestoreSync: Error listening to guide itinerary items for guide $guideId',
            e,
          ),
        );
    _subscriptions.add(sub);
  }

  Future<void> _handleGuideItinerarySnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _upsertGuideItineraryItemToLocal(change.doc.id, data);
          break;
        case DocumentChangeType.removed:
          // Soft-delete locally
          await (_db.update(
            _db.guideItineraryItems,
          )..where((i) => i.id.equals(change.doc.id))).write(
            GuideItineraryItemsCompanion(
              isDeleted: const drift.Value(true),
              lastSyncedAt: drift.Value(DateTime.now()),
            ),
          );
          break;
      }
    }
  }

  Future<void> _upsertGuideItineraryItemToLocal(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final now = DateTime.now();
      final companion = GuideItineraryItemsCompanion.insert(
        id: itemId,
        guideId: data['guideId'] as String,
        title: data['title'] as String,
        description: drift.Value(data['description'] as String?),
        locationName: drift.Value(data['locationName'] as String?),
        latitude: drift.Value(data['latitude'] as double?),
        longitude: drift.Value(data['longitude'] as double?),
        dayNumber: data['dayNumber'] as int? ?? 1,
        suggestedStartTime: drift.Value(
          _parseTimestamp(data['suggestedStartTime']),
        ),
        suggestedEndTime: drift.Value(
          _parseTimestamp(data['suggestedEndTime']),
        ),
        category: drift.Value(data['category'] as String? ?? 'other'),
        sortOrder: drift.Value(data['sortOrder'] as int? ?? 0),
        estimatedCost: drift.Value(data['estimatedCost'] as double?),
        costCurrency: drift.Value(data['costCurrency'] as String?),
        createdAt: _parseTimestamp(data['createdAt']) ?? now,
        updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
        lastSyncedAt: drift.Value(now),
        isDeleted: drift.Value(data['isDeleted'] as bool? ?? false),
      );

      await _db
          .into(_db.guideItineraryItems)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);
      AppLogger.talker.debug(
        'FirestoreSync: Upserted guide itinerary item $itemId',
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'FirestoreSync: Failed to upsert guide itinerary item $itemId',
        e,
        st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility
  // ═══════════════════════════════════════════════════════════════════════════

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Riverpod provider for FirestoreSyncService.
///
/// This is a keep-alive provider because the service manages long-lived
/// stream subscriptions. Call [FirestoreSyncService.startListeners] after
/// authentication and [FirestoreSyncService.stopListeners] on sign-out.
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);
  return FirestoreSyncService(
    db,
    FirebaseFirestore.instance,
    auth.FirebaseAuth.instance,
    onNewInvitation: (invitationId, tripTitle, inviterName) {
      notificationService.showInvitationNotification(
        invitationId: invitationId,
        tripTitle: tripTitle,
        inviterName: inviterName,
      );
    },
  );
});
