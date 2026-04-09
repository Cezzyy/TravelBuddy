import 'package:drift/drift.dart';

import 'users.dart';

/// Travel guides with blog-like content and itineraries.
class Guides extends Table {
  TextColumn get id => text()();
  TextColumn get authorId => text().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text()();
  TextColumn get destination => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  TextColumn get content => text()();
  TextColumn get tags => text().nullable()();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  IntColumn get likeCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
