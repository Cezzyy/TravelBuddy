import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/local_notification_service.dart';
import 'firebase_options.dart';
import 'shared/data/app_db.dart';
import 'shared/data/providers/database_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.talker.info('Firebase initialized');

  final database = AppDatabase();
  AppLogger.talker.info('Drift database initialized');

  // Create a temporary ProviderScope just for initializing notifications
  // This is needed because LocalNotificationService requires a Ref
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );
  await container.read(localNotificationServiceProvider).init();
  AppLogger.talker.info('Local notifications initialized');

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.environment;
      options.tracesSampleRate = AppConfig.isProduction ? 0.2 : 1.0;
      options.beforeSend = (event, hint) {
        if (AppConfig.sentryDsn.isEmpty) return null;
        return event;
      };
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        observers: [
          TalkerRiverpodObserver(
            talker: AppLogger.talker,
            settings: TalkerRiverpodLoggerSettings(
              printProviderAdded: true,
              printProviderUpdated: true,
              printProviderDisposed: true,
              printProviderFailed: true,
            ),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}
