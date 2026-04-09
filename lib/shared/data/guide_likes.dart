import 'package:drift/drift.dart';

import 'users.dart';

/// User likes on guides.
class GuideLikes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get guideId => text()();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get likedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {guideId, userId},
  ];
}
