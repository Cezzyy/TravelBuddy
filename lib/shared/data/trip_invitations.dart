import 'package:drift/drift.dart';

import 'trips.dart';
import 'users.dart';

/// Trip invitations for collaborative planning.
class TripInvitations extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get invitedByUserId => text().references(Users, #id)();
  TextColumn get invitedEmail => text()();
  TextColumn get invitedUserId => text().nullable().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get respondedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
