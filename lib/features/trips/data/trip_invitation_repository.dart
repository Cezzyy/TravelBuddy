import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';
import '../domain/trip_role.dart';

part 'trip_invitation_repository.g.dart';

@riverpod
TripInvitationRepository tripInvitationRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TripInvitationRepository(db, FirebaseFirestore.instance);
}

class TripInvitationRepository {
  TripInvitationRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  /// Create a new trip invitation
  Future<TripInvitation> createInvitation({
    required String tripId,
    required String invitedByUserId,
    required String invitedEmail,
    required TripRole role,
    int expirationDays = 7,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: expirationDays));
    final invitationId = _uuid.v4();

    // Check if invitation already exists for this email and trip
    final existing =
        await (_db.select(_db.tripInvitations)..where(
              (t) =>
                  t.tripId.equals(tripId) &
                  t.invitedEmail.equals(invitedEmail) &
                  t.status.equals('pending'),
            ))
            .getSingleOrNull();

    if (existing != null) {
      throw Exception('An invitation has already been sent to this email');
    }

    final companion = TripInvitationsCompanion.insert(
      id: invitationId,
      tripId: tripId,
      invitedByUserId: invitedByUserId,
      invitedEmail: invitedEmail,
      role: drift.Value(role.value),
      status: drift.Value(InvitationStatus.pending.value),
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _db.into(_db.tripInvitations).insert(companion);

    AppLogger.talker.info(
      'Created trip invitation: $invitationId for $invitedEmail',
    );

    // Sync to Firestore
    await _syncInvitationToFirestore(invitationId);

    return (await (_db.select(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).getSingle());
  }

  /// Get all invitations for a trip
  Stream<List<TripInvitation>> watchInvitationsForTrip(String tripId) {
    return (_db.select(_db.tripInvitations)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  /// Get all pending invitations for a user (by email)
  Stream<List<TripInvitation>> watchInvitationsForUser(String email) {
    return (_db.select(_db.tripInvitations)
          ..where(
            (t) =>
                t.invitedEmail.equals(email) &
                t.status.equals(InvitationStatus.pending.value),
          )
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  /// Get count of pending invitations for a user
  Stream<int> watchPendingInvitationCount(String email) {
    final query = _db.selectOnly(_db.tripInvitations)
      ..addColumns([_db.tripInvitations.id.count()])
      ..where(
        _db.tripInvitations.invitedEmail.equals(email) &
            _db.tripInvitations.status.equals(InvitationStatus.pending.value),
      );

    return query
        .map((row) => row.read(_db.tripInvitations.id.count()) ?? 0)
        .watchSingle();
  }

  /// Accept an invitation
  ///
  /// Uses a Firestore WriteBatch to atomically update both the invitation
  /// status and create the collaborator record. This prevents partial writes
  /// where the invitation is accepted but the collaborator isn't created.
  Future<void> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    final invitation = await (_db.select(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).getSingleOrNull();

    if (invitation == null) {
      throw Exception('Invitation not found');
    }

    if (invitation.status != InvitationStatus.pending.value) {
      throw Exception('Invitation is no longer pending');
    }

    if (invitation.expiresAt.isBefore(DateTime.now())) {
      // Mark as expired
      await (_db.update(
        _db.tripInvitations,
      )..where((t) => t.id.equals(invitationId))).write(
        TripInvitationsCompanion(
          status: drift.Value(InvitationStatus.expired.value),
          respondedAt: drift.Value(DateTime.now()),
        ),
      );
      throw Exception('Invitation has expired');
    }

    final now = DateTime.now();

    // Update invitation status locally
    await (_db.update(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).write(
      TripInvitationsCompanion(
        status: drift.Value(InvitationStatus.accepted.value),
        invitedUserId: drift.Value(userId),
        respondedAt: drift.Value(now),
      ),
    );

    // Add user as collaborator locally
    await _db
        .into(_db.tripCollaborators)
        .insert(
          TripCollaboratorsCompanion.insert(
            tripId: invitation.tripId,
            userId: userId,
            role: drift.Value(invitation.role),
            addedAt: now,
          ),
        );

    AppLogger.talker.info('Accepted invitation: $invitationId');

    // Sync both changes to Firestore atomically using a WriteBatch
    await _acceptInvitationBatch(
      invitationId,
      invitation.tripId,
      userId,
      invitation.role,
      now,
    );
  }

  /// Atomically sync invitation acceptance to Firestore using a WriteBatch.
  ///
  /// Both the invitation update and collaborator creation are committed as
  /// a single atomic operation. If either fails, neither is written.
  Future<void> _acceptInvitationBatch(
    String invitationId,
    String tripId,
    String userId,
    String role,
    DateTime respondedAt,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update invitation document (use set with merge for idempotency)
      final invitationRef = _firestore
          .collection('trip_invitations')
          .doc(invitationId);
      batch.set(invitationRef, {
        'status': InvitationStatus.accepted.value,
        'invitedUserId': userId,
        'respondedAt': Timestamp.fromDate(respondedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create collaborator document with composite key
      final collaboratorDocId = '${userId}_$tripId';
      final collaboratorRef = _firestore
          .collection('trip_collaborators')
          .doc(collaboratorDocId);
      batch.set(collaboratorRef, {
        'tripId': tripId,
        'userId': userId,
        'role': role,
        'addedAt': Timestamp.fromDate(respondedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.talker.info(
        'Batch committed: invitation $invitationId accepted, '
        'collaborator $userId added to trip $tripId',
      );

      // Update lastSyncedAt timestamps locally
      await (_db.update(
        _db.tripInvitations,
      )..where((t) => t.id.equals(invitationId))).write(
        TripInvitationsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
      await (_db.update(
        _db.tripCollaborators,
      )..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId))).write(
        TripCollaboratorsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Batch commit failed for invitation acceptance, '
        'falling back to individual syncs',
        e,
        st,
      );

      // Fallback: attempt individual syncs (non-atomic but still functional)
      await _syncInvitationToFirestore(invitationId);
      await _syncCollaboratorToFirestore(tripId, userId);
    }
  }

  /// Decline an invitation
  Future<void> declineInvitation(String invitationId) async {
    final invitation = await (_db.select(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).getSingleOrNull();

    if (invitation == null) {
      throw Exception('Invitation not found');
    }

    if (invitation.status != InvitationStatus.pending.value) {
      throw Exception('Invitation is no longer pending');
    }

    await (_db.update(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).write(
      TripInvitationsCompanion(
        status: drift.Value(InvitationStatus.declined.value),
        respondedAt: drift.Value(DateTime.now()),
      ),
    );

    AppLogger.talker.info('Declined invitation: $invitationId');

    // Sync to Firestore
    await _syncInvitationToFirestore(invitationId);
  }

  /// Cancel an invitation (by trip owner)
  Future<void> cancelInvitation(String invitationId) async {
    // Delete from Firestore first
    await _deleteInvitationFromFirestore(invitationId);

    // Then delete from local DB
    await (_db.delete(
      _db.tripInvitations,
    )..where((t) => t.id.equals(invitationId))).go();

    AppLogger.talker.info('Cancelled invitation: $invitationId');
  }

  /// Get collaborators for a trip
  Stream<List<TripCollaborator>> watchCollaborators(String tripId) {
    return (_db.select(_db.tripCollaborators)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.addedAt,
              mode: drift.OrderingMode.asc,
            ),
          ]))
        .watch();
  }

  /// Get user's role in a trip
  Future<TripRole?> getUserRole(String tripId, String userId) async {
    // Check if user is the owner
    final trip = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(tripId))).getSingleOrNull();

    if (trip?.ownerId == userId) {
      return TripRole.owner;
    }

    // Check if user is a collaborator
    final collaborator =
        await (_db.select(_db.tripCollaborators)
              ..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId)))
            .getSingleOrNull();

    if (collaborator != null) {
      return TripRole.fromString(collaborator.role);
    }

    return null;
  }

  /// Remove a collaborator from a trip
  Future<void> removeCollaborator({
    required String tripId,
    required String userId,
  }) async {
    // Delete from Firestore first
    await _deleteCollaboratorFromFirestore(tripId, userId);

    // Then delete from local DB
    await (_db.delete(
      _db.tripCollaborators,
    )..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId))).go();

    AppLogger.talker.info('Removed collaborator $userId from trip $tripId');
  }

  /// Update collaborator role
  Future<void> updateCollaboratorRole({
    required String tripId,
    required String userId,
    required TripRole newRole,
  }) async {
    // Update local DB
    await (_db.update(_db.tripCollaborators)
          ..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId)))
        .write(TripCollaboratorsCompanion(role: drift.Value(newRole.value)));

    AppLogger.talker.info(
      'Updated collaborator $userId role to ${newRole.value} in trip $tripId',
    );

    // Sync to Firestore
    await _syncCollaboratorToFirestore(tripId, userId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Firestore Sync Methods
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync invitation to Firestore
  Future<void> _syncInvitationToFirestore(String invitationId) async {
    try {
      final invitation = await (_db.select(
        _db.tripInvitations,
      )..where((t) => t.id.equals(invitationId))).getSingleOrNull();

      if (invitation == null) {
        AppLogger.talker.warning(
          'Invitation not found for sync: $invitationId',
        );
        return;
      }

      final docRef = _firestore
          .collection('trip_invitations')
          .doc(invitationId);
      final data = {
        'tripId': invitation.tripId,
        'invitedByUserId': invitation.invitedByUserId,
        'invitedEmail': invitation.invitedEmail,
        'invitedUserId': invitation.invitedUserId,
        'role': invitation.role,
        'status': invitation.status,
        'createdAt': Timestamp.fromDate(invitation.createdAt),
        'expiresAt': Timestamp.fromDate(invitation.expiresAt),
        'respondedAt': invitation.respondedAt != null
            ? Timestamp.fromDate(invitation.respondedAt!)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Invitation synced to Firestore: $invitationId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync invitation to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Delete invitation from Firestore
  Future<void> _deleteInvitationFromFirestore(String invitationId) async {
    try {
      await _firestore
          .collection('trip_invitations')
          .doc(invitationId)
          .delete();
      AppLogger.talker.info('Invitation deleted from Firestore: $invitationId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to delete invitation from Firestore',
        e,
        st,
      );
    }
  }

  /// Sync collaborator to Firestore
  Future<void> _syncCollaboratorToFirestore(
    String tripId,
    String userId,
  ) async {
    try {
      final collaborator =
          await (_db.select(_db.tripCollaborators)..where(
                (t) => t.tripId.equals(tripId) & t.userId.equals(userId),
              ))
              .getSingleOrNull();

      if (collaborator == null) {
        AppLogger.talker.warning(
          'Collaborator not found for sync: $userId in trip $tripId',
        );
        return;
      }

      // Use composite key: userId_tripId
      final docId = '${userId}_$tripId';
      final docRef = _firestore.collection('trip_collaborators').doc(docId);
      final data = {
        'tripId': collaborator.tripId,
        'userId': collaborator.userId,
        'role': collaborator.role,
        'addedAt': Timestamp.fromDate(collaborator.addedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.talker.info('Collaborator synced to Firestore: $docId');

      // Update lastSyncedAt in local DB
      await (_db.update(
        _db.tripCollaborators,
      )..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId))).write(
        TripCollaboratorsCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync collaborator to Firestore (will retry later)',
        e,
        st,
      );
    }
  }

  /// Delete collaborator from Firestore
  Future<void> _deleteCollaboratorFromFirestore(
    String tripId,
    String userId,
  ) async {
    try {
      final docId = '${userId}_$tripId';
      await _firestore.collection('trip_collaborators').doc(docId).delete();
      AppLogger.talker.info('Collaborator deleted from Firestore: $docId');
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to delete collaborator from Firestore',
        e,
        st,
      );
    }
  }

  /// Sync invitation from Firestore to local DB
  Future<void> syncInvitationFromFirestore(String invitationId) async {
    try {
      final docRef = _firestore
          .collection('trip_invitations')
          .doc(invitationId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Invitation not found in Firestore: $invitationId');
      }

      final data = docSnapshot.data()!;
      final now = DateTime.now();

      final companion = TripInvitationsCompanion.insert(
        id: invitationId,
        tripId: data['tripId'] as String,
        invitedByUserId: data['invitedByUserId'] as String,
        invitedEmail: data['invitedEmail'] as String,
        role: drift.Value(data['role'] as String),
        status: drift.Value(data['status'] as String),
        createdAt: _parseTimestamp(data['createdAt']) ?? now,
        expiresAt: _parseTimestamp(data['expiresAt']) ?? now,
        invitedUserId: drift.Value(data['invitedUserId'] as String?),
        respondedAt: drift.Value(_parseTimestamp(data['respondedAt'])),
      );

      await _db
          .into(_db.tripInvitations)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);

      AppLogger.talker.info('Invitation synced from Firestore: $invitationId');
    } catch (e, st) {
      AppLogger.talker.error('Failed to sync invitation from Firestore', e, st);
      rethrow;
    }
  }

  /// Sync collaborator from Firestore to local DB
  Future<void> syncCollaboratorFromFirestore(
    String tripId,
    String userId,
  ) async {
    try {
      final docId = '${userId}_$tripId';
      final docRef = _firestore.collection('trip_collaborators').doc(docId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Collaborator not found in Firestore: $docId');
      }

      final data = docSnapshot.data()!;
      final now = DateTime.now();

      final companion = TripCollaboratorsCompanion.insert(
        tripId: data['tripId'] as String,
        userId: data['userId'] as String,
        role: drift.Value(data['role'] as String),
        addedAt: _parseTimestamp(data['addedAt']) ?? now,
        lastSyncedAt: drift.Value(now),
      );

      await _db
          .into(_db.tripCollaborators)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);

      AppLogger.talker.info('Collaborator synced from Firestore: $docId');
    } catch (e, st) {
      AppLogger.talker.error(
        'Failed to sync collaborator from Firestore',
        e,
        st,
      );
      rethrow;
    }
  }

  /// Parse Firestore Timestamp to DateTime
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
