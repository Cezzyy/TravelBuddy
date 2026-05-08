import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'users.dart';
import 'user_preferences.dart';
import 'trips.dart';
import 'trip_collaborators.dart';
import 'trip_invitations.dart';
import 'itinerary_items.dart';
import 'guides.dart';
import 'guide_itinerary_items.dart';
import 'guide_likes.dart';
import 'guide_comments.dart';
import 'trip_guide_references.dart';
import 'sync_queue.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    Users,
    UserPreferences,
    Trips,
    TripCollaborators,
    TripInvitations,
    ItineraryItems,
    Guides,
    GuideItineraryItems,
    GuideLikes,
    GuideComments,
    TripGuideReferences,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from v1 to v2: Add guides and invitation tables
        if (from < 2) {
          // Add new tables for guides system
          await m.createTable(guides);
          await m.createTable(guideItineraryItems);
          await m.createTable(guideLikes);
          await m.createTable(guideComments);
          await m.createTable(tripGuideReferences);

          // Add trip invitations table
          await m.createTable(tripInvitations);
        }
        
        // Migration from v2 to v3: Add draft versioning to guides
        if (from < 3) {
          await m.addColumn(guides, guides.publishedVersionId);
          await m.addColumn(guides, guides.draftVersionId);
        }
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
