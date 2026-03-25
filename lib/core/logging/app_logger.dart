import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Central logging singleton. All app logging flows through here.
/// Talker handles local console/UI logs, Sentry handles remote crash reporting.
class AppLogger {
  AppLogger._();

  static late final Talker _talker;

  /// Access the Talker instance anywhere in the app.
  static Talker get talker => _talker;

  /// Initialize Talker with a Sentry observer so errors automatically
  /// get forwarded to both console and Sentry.
  static void init() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        useConsoleLogs: true,
      ),
      observer: _SentryTalkerObserver(),
    );

    _talker.info('AppLogger initialized');
  }
}

/// Bridges Talker → Sentry. Errors and exceptions logged via Talker
/// automatically get sent to Sentry for remote tracking.
class _SentryTalkerObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    Sentry.captureException(
      err.error,
      stackTrace: err.stackTrace,
    );
    super.onError(err);
  }

  @override
  void onException(TalkerException exception) {
    Sentry.captureException(
      exception.exception,
      stackTrace: exception.stackTrace,
    );
    super.onException(exception);
  }
}
