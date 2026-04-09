import 'package:drift/drift.dart';

/// Links trips to guides when imported.
class TripGuideReferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text()();
  TextColumn get guideId => text()();
  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {tripId, guideId},
  ];
}
