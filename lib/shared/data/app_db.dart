import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'users.dart';
import 'user_preferences.dart';
import 'trips.dart';
import 'trip_collaborators.dart';
import 'itinerary_items.dart';
import 'sync_queue.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    Users,
    UserPreferences,
    Trips,
    TripCollaborators,
    ItineraryItems,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  /// Factory that opens the database from the app's documents directory.
  factory AppDatabase() {
    return AppDatabase._internal(_openConnection());
  }

  /// For testing — pass in an in-memory or custom executor.
  AppDatabase.forTesting(super.e);

  // Bump this number whenever you change the schema, then add a migration.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here. Example:
        // if (from < 2) {
        //   await m.addColumn(trips, trips.someNewColumn);
        // }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    await getApplicationDocumentsDirectory();
    // Use sqflite for better cross-platform support
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'travelbuddy.sqlite',
      logStatements: true,
    );
  });
}
