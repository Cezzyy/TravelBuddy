import 'package:drift/drift.dart';

import 'users.dart';

/// Onboarding step 2: travel preferences.
/// Separate table so `preferences == null` check is just "row exists?".
class UserPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();

  // One-to-one with Users
  TextColumn get userId => text().unique().references(Users, #id)();

  // Preference fields
  TextColumn get travelStyle =>
      text().nullable()(); // adventure, relaxation, cultural
  TextColumn get budgetLevel =>
      text().nullable()(); // budget, mid-range, luxury
  TextColumn get preferredActivities =>
      text().nullable()(); // JSON-encoded list

  // Timestamps
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}
