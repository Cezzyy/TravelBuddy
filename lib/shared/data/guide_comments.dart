import 'package:drift/drift.dart';

import 'users.dart';

/// Comments on guides.
class GuideComments extends Table {
  TextColumn get id => text()();
  TextColumn get guideId => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
