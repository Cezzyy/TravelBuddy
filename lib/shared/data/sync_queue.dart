import 'package:drift/drift.dart';

/// Offline-first sync queue. Every local write queues a row here.
/// Sync service processes pending items when connectivity returns.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Which table was modified
  TextColumn get targetTable => text()();

  // Primary key of the modified record
  TextColumn get recordId => text()();

  // create, update, delete
  TextColumn get operation => text()();

  // JSON snapshot of the change payload
  TextColumn get payload => text()();

  // When the change happened locally
  DateTimeColumn get createdAt => dateTime()();

  // Retry logic
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // pending, in_progress, failed, completed
  TextColumn get status => text().withDefault(const Constant('pending'))();
}
