import 'package:drift/drift.dart';

import 'users.dart';

/// Core trip entity. Status powers "Upcoming" vs "Past" home sections.
class Trips extends Table {
  // Firestore document ID
  TextColumn get id => text()();

  // Owner reference
  TextColumn get ownerId => text().references(Users, #id)();

  // Trip details
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get destination => text()();

  // Geocoded coordinates (from geocoding/geolocator packages)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  // Cover image from Firebase Storage
  TextColumn get coverImageUrl => text().nullable()();

  // Date range
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  // upcoming, ongoing, completed, cancelled
  TextColumn get status => text().withDefault(const Constant('upcoming'))();

  // Timestamps & sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  // Soft delete for sync conflict resolution
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
