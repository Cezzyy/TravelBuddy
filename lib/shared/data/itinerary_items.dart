import 'package:drift/drift.dart';

import 'trips.dart';
import 'users.dart';

/// The "many" side of Trip → Many Itinerary Items.
/// Supports day-based grouping, manual reordering, and category filtering.
class ItineraryItems extends Table {
  // Firestore document ID
  TextColumn get id => text()();

  // Parent trip
  TextColumn get tripId => text().references(Trips, #id)();

  // Item details
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get description => text().nullable()();

  // Location
  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  // Scheduling
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();

  // transport, food, activity, accommodation, other
  TextColumn get category => text().withDefault(const Constant('other'))();

  // For drag-and-drop reordering within a day
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // Who added it (for collaborative tracking)
  TextColumn get createdBy => text().references(Users, #id)();

  // Timestamps & sync
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  // Soft delete
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
