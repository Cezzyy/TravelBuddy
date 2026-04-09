import 'package:drift/drift.dart';

/// Reusable itinerary templates within guides.
class GuideItineraryItems extends Table {
  TextColumn get id => text()();
  TextColumn get guideId => text()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get description => text().nullable()();
  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get dayNumber => integer()();
  DateTimeColumn get suggestedStartTime => dateTime().nullable()();
  DateTimeColumn get suggestedEndTime => dateTime().nullable()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  RealColumn get estimatedCost => real().nullable()();
  TextColumn get costCurrency => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
