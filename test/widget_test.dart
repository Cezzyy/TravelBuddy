import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:travelbuddy/app.dart';
import 'package:travelbuddy/features/auth/data/auth_repository.dart';
import 'package:travelbuddy/features/auth/data/user_repository.dart';
import 'package:travelbuddy/shared/data/app_db.dart';
import 'package:travelbuddy/shared/data/providers/database_provider.dart';

// Mock AuthRepository for testing
class MockAuthRepository implements AuthRepository {
  @override
  Stream<firebase_auth.User?> authStateChanges() => Stream.value(null);

  @override
  firebase_auth.User? get currentUser => null;

  @override
  Future<firebase_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Mock method for testing');
  }

  @override
  Future<firebase_auth.UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('Mock method for testing');
  }

  @override
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    throw UnimplementedError('Mock method for testing');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> clearLocalData() async {}
}

// Mock UserRepository for testing
class MockUserRepository implements UserRepository {
  @override
  Future<User?> getLocalUser(String userId) async => null;

  @override
  Stream<User?> watchLocalUser(String userId) => Stream.value(null);

  @override
  Future<User> syncUserFromAuth(firebase_auth.User firebaseUser) async {
    throw UnimplementedError('Mock method for testing');
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? location,
    bool? isProfileComplete,
    bool? hasAgreedToRules,
  }) async {}

  @override
  Future<UserPreference?> getUserPreferences(String userId) async => null;

  @override
  Stream<UserPreference?> watchUserPreferences(String userId) =>
      Stream.value(null);

  @override
  Future<void> updateUserPreferences({
    required String userId,
    String? travelStyle,
    String? budgetLevel,
    String? preferredActivities,
  }) async {}

  @override
  Future<void> clearAllLocalData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test — renders without crashing', (tester) async {
    final database = AppDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          userRepositoryProvider.overrideWithValue(MockUserRepository()),
        ],
        child: const App(),
      ),
    );

    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(seconds: 1));

    database.close();
  });
}
