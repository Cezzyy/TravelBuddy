import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../../../core/logging/app_logger.dart';
import '../../../shared/data/app_db.dart';
import 'package:drift/drift.dart' as drift;

/// Background sync service to sync Firestore data to local DB
/// This runs AFTER authentication and onboarding are complete
/// Used for offline features like trips, guides, etc.
class BackgroundSync {
  BackgroundSync(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  /// Sync user data from Firestore to local DB
  /// Call this after onboarding is complete
  Future<void> syncUserToLocalDB(auth.User firebaseUser) async {
    try {
      AppLogger.talker.info('Background sync: Syncing user to local DB');

      final docSnapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!docSnapshot.exists) {
        AppLogger.talker.warning('User document does not exist in Firestore');
        return;
      }

      final data = docSnapshot.data()!;
      final now = DateTime.now();

      // Sync user to local DB
      final userCompanion = UsersCompanion.insert(
        id: firebaseUser.uid,
        email: data['email'] as String? ?? '',
        displayName: drift.Value(data['displayName'] as String?),
        photoUrl: drift.Value(data['photoUrl'] as String?),
        isProfileComplete: drift.Value(
          data['isProfileComplete'] as bool? ?? false,
        ),
        hasAgreedToRules: drift.Value(
          data['hasAgreedToRules'] as bool? ?? false,
        ),
        createdAt: _parseTimestamp(data['createdAt']) ?? now,
        updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
        lastSyncedAt: drift.Value(now),
      );

      await _db
          .into(_db.users)
          .insert(userCompanion, mode: drift.InsertMode.insertOrReplace);

      AppLogger.talker.info('User synced to local DB');

      // Sync preferences if they exist
      if (data['preferences'] != null) {
        final prefs = data['preferences'] as Map<String, dynamic>;
        final prefsCompanion = UserPreferencesCompanion.insert(
          userId: firebaseUser.uid,
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

        AppLogger.talker.info('User preferences synced to local DB');
      }
    } catch (e, st) {
      AppLogger.talker.error('Background sync failed', e, st);
      // Don't throw - this is background sync, app should continue working
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
