import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_db.dart';

part 'database_provider.g.dart';

/// Provides the single AppDatabase instance across the app.
/// Initialized at startup via ProviderScope override in main.dart.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabase must be overridden in ProviderScope with a real instance.',
  );
}
