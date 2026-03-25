import 'package:drift/drift.dart';

/// Local mirror of Firebase Auth + Firestore user document.
/// Gates onboarding flow via [isProfileComplete] and [hasAgreedToRules].
class Users extends Table {
  // Firebase UID as primary key
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();

  // Onboarding gates
  BoolColumn get isProfileComplete => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAgreedToRules => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
