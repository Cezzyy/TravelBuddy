import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../../../core/logging/app_logger.dart';

/// User data model from Firestore
class FirestoreUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isProfileComplete;
  final bool hasAgreedToRules;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences;

  FirestoreUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isProfileComplete,
    required this.hasAgreedToRules,
    this.createdAt,
    this.updatedAt,
    this.preferences,
  });

  factory FirestoreUser.fromFirestore(String id, Map<String, dynamic> data) {
    return FirestoreUser(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      hasAgreedToRules: data['hasAgreedToRules'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }
}

/// Provides the current user data from Firestore
/// Returns null if user is not authenticated
final firestoreUserProvider = StreamProvider<FirestoreUser?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final firestore = FirebaseFirestore.instance;

  await for (final firebaseUser in authRepo.authStateChanges()) {
    if (firebaseUser == null) {
      AppLogger.talker.debug('No Firebase user, yielding null');
      yield null;
      continue;
    }

    final uid = firebaseUser.uid;
    final email = firebaseUser.email;
    AppLogger.talker.info(
      'Loading Firestore user data for: $uid (email: $email)',
    );

    try {
      // Watch the Firestore document for real-time updates
      await for (final docSnapshot
          in firestore.collection('users').doc(uid).snapshots()) {
        if (!docSnapshot.exists) {
          AppLogger.talker.warning('User document does not exist: $uid');
          yield null;
          continue;
        }

        final data = docSnapshot.data()!;
        final user = FirestoreUser.fromFirestore(uid, data);
        AppLogger.talker.info(
          'Firestore user data loaded - ID: ${user.id}, Email: ${user.email}, Name: ${user.displayName}',
        );
        yield user;
      }
    } catch (e, st) {
      AppLogger.talker.error('Error loading Firestore user', e, st);
      yield null;
    }
  }
});
