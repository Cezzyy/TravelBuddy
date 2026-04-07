import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import '../../../shared/data/providers/database_provider.dart';

part 'user_repository.g.dart';

/// Repository for user data sync between Firebase Firestore and local Drift DB.
/// Implements offline-first pattern: write to Drift immediately, sync to Firestore.
@riverpod
UserRepository userRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserRepository(db, FirebaseFirestore.instance);
}

class UserRepository {
  UserRepository(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Get user from local DB by ID.
  Future<User?> getLocalUser(String userId) async {
    return await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
  }

  /// Stream of local user data.
  Stream<User?> watchLocalUser(String userId) {
    return (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).watchSingleOrNull();
  }

  /// Sync user from Firebase Auth to local DB and Firestore.
  /// Called after successful authentication.
  Future<User> syncUserFromAuth(auth.User firebaseUser) async {
    AppLogger.talker.info(
      'Syncing user from Firebase Auth: ${firebaseUser.uid}',
    );

    // Check if user exists in Firestore
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await docRef.get();

    final now = DateTime.now();
    User localUser;

    if (docSnapshot.exists) {
      // User exists in Firestore, sync to local DB
      final data = docSnapshot.data()!;
      localUser = await _syncFromFirestore(firebaseUser.uid, data);
      AppLogger.talker.info('User synced from Firestore to local DB');
    } else {
      // New user, create in both Firestore and local DB
      final userData = {
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
        'isProfileComplete': false,
        'hasAgreedToRules': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(userData);
      AppLogger.talker.info('New user created in Firestore');

      // Create in local DB
      final companion = UsersCompanion.insert(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: drift.Value(firebaseUser.displayName),
        photoUrl: drift.Value(firebaseUser.photoURL),
        isProfileComplete: const drift.Value(false),
        hasAgreedToRules: const drift.Value(false),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: drift.Value(now),
      );

      await _db
          .into(_db.users)
          .insert(companion, mode: drift.InsertMode.insertOrReplace);

      localUser = (await getLocalUser(firebaseUser.uid))!;
      AppLogger.talker.info('New user created in local DB');
    }

    return localUser;
  }

  /// Sync user data from Firestore to local DB.
  Future<User> _syncFromFirestore(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now();

    final companion = UsersCompanion.insert(
      id: userId,
      email: data['email'] as String? ?? '',
      displayName: drift.Value(data['displayName'] as String?),
      photoUrl: drift.Value(data['photoUrl'] as String?),
      isProfileComplete: drift.Value(
        data['isProfileComplete'] as bool? ?? false,
      ),
      hasAgreedToRules: drift.Value(data['hasAgreedToRules'] as bool? ?? false),
      createdAt: _parseTimestamp(data['createdAt']) ?? now,
      updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
      lastSyncedAt: drift.Value(now),
    );

    await _db
        .into(_db.users)
        .insert(companion, mode: drift.InsertMode.insertOrReplace);

    // Sync preferences if they exist in Firestore
    if (data['preferences'] != null) {
      final prefs = data['preferences'] as Map<String, dynamic>;
      final prefsCompanion = UserPreferencesCompanion.insert(
        userId: userId,
        travelStyle: drift.Value(prefs['travelStyle'] as String?),
        budgetLevel: drift.Value(prefs['budgetLevel'] as String?),
        preferredActivities: drift.Value(
          prefs['preferredActivities'] as String?,
        ),
        updatedAt: _parseTimestamp(prefs['updatedAt']) ?? now,
      );

      await _db
          .into(_db.userPreferences)
          .insert(prefsCompanion, mode: drift.InsertMode.insertOrReplace);
      AppLogger.talker.info('User preferences synced from Firestore');
    }

    return (await getLocalUser(userId))!;
  }

  /// Update user profile locally and queue for sync.
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    bool? isProfileComplete,
    bool? hasAgreedToRules,
  }) async {
    final now = DateTime.now();

    // Update local DB
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        displayName: displayName != null
            ? drift.Value(displayName)
            : const drift.Value.absent(),
        photoUrl: photoUrl != null
            ? drift.Value(photoUrl)
            : const drift.Value.absent(),
        isProfileComplete: isProfileComplete != null
            ? drift.Value(isProfileComplete)
            : const drift.Value.absent(),
        hasAgreedToRules: hasAgreedToRules != null
            ? drift.Value(hasAgreedToRules)
            : const drift.Value.absent(),
        updatedAt: drift.Value(now),
      ),
    );

    AppLogger.talker.info('User profile updated locally');

    // Queue for sync
    final payload = <String, dynamic>{
      'displayName': ?displayName,
      'photoUrl': ?photoUrl,
      'isProfileComplete': ?isProfileComplete,
      'hasAgreedToRules': ?hasAgreedToRules,
      'updatedAt': now.toIso8601String(),
    };

    await _queueSync(
      targetTable: 'users',
      recordId: userId,
      operation: 'update',
      payload: payload,
    );

    // Attempt immediate sync if online
    await _syncToFirestore(userId, payload);
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

  /// Sync local changes to Firestore.
  Future<void> _syncToFirestore(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      await docRef.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
      AppLogger.talker.info('User synced to Firestore');

      // Update lastSyncedAt in local DB
      await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(lastSyncedAt: drift.Value(DateTime.now())),
      );
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync to Firestore (will retry later)',
        e,
        st,
      );
      // Sync queue will handle retry
    }
  }

  /// Parse Firestore Timestamp to DateTime.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Get user preferences from local DB.
  Future<UserPreference?> getUserPreferences(String userId) async {
    return await (_db.select(
      _db.userPreferences,
    )..where((p) => p.userId.equals(userId))).getSingleOrNull();
  }

  /// Stream of local user preferences.
  Stream<UserPreference?> watchUserPreferences(String userId) {
    return (_db.select(
      _db.userPreferences,
    )..where((p) => p.userId.equals(userId))).watchSingleOrNull();
  }

  /// Update user preferences locally and queue for sync.
  Future<void> updateUserPreferences({
    required String userId,
    String? travelStyle,
    String? budgetLevel,
    String? preferredActivities,
  }) async {
    final now = DateTime.now();

    // Check if preferences exist
    final existing = await getUserPreferences(userId);

    if (existing == null) {
      // Insert new preferences
      await _db
          .into(_db.userPreferences)
          .insert(
            UserPreferencesCompanion.insert(
              userId: userId,
              travelStyle: drift.Value(travelStyle),
              budgetLevel: drift.Value(budgetLevel),
              preferredActivities: drift.Value(preferredActivities),
              updatedAt: now,
            ),
          );
    } else {
      // Update existing preferences
      await (_db.update(
        _db.userPreferences,
      )..where((p) => p.userId.equals(userId))).write(
        UserPreferencesCompanion(
          travelStyle: travelStyle != null
              ? drift.Value(travelStyle)
              : const drift.Value.absent(),
          budgetLevel: budgetLevel != null
              ? drift.Value(budgetLevel)
              : const drift.Value.absent(),
          preferredActivities: preferredActivities != null
              ? drift.Value(preferredActivities)
              : const drift.Value.absent(),
          updatedAt: drift.Value(now),
        ),
      );
    }

    AppLogger.talker.info('User preferences updated locally');

    // Queue for Firestore sync
    final payload = <String, dynamic>{
      'travelStyle': ?travelStyle,
      'budgetLevel': ?budgetLevel,
      'preferredActivities': ?preferredActivities,
      'updatedAt': now.toIso8601String(),
    };

    await _queueSync(
      targetTable: 'user_preferences',
      recordId: userId,
      operation: existing == null ? 'create' : 'update',
      payload: payload,
    );

    // Attempt immediate sync
    try {
      final docRef = _firestore.collection('users').doc(userId);
      await docRef.update({
        'preferences': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.talker.info('User preferences synced to Firestore');
    } catch (e, st) {
      AppLogger.talker.warning(
        'Failed to sync preferences (will retry later)',
        e,
        st,
      );
    }
  }
}
