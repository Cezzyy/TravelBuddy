import 'package:drift/drift.dart';

import 'trips.dart';
import 'users.dart';

/// Join table for shared/collaborative trips.
/// Maps to Firestore's collaboratorIds array but as proper relations.
class TripCollaborators extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Composite foreign keys
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get userId => text().references(Users, #id)();

  // owner, editor, viewer
  TextColumn get role => text().withDefault(const Constant('viewer'))();

  // Timestamps
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tripId, userId},
      ];
}
