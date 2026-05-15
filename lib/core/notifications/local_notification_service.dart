import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';

class LocalNotificationService {
  LocalNotificationService(this._ref);

  final Ref _ref;

  static const _channelId = 'trip_invitations';
  static const _channelName = 'Trip Invitations';
  static const _channelDescription =
      'Notifications for trip collaboration invites';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
      }
    }

    _initialized = true;
    AppLogger.talker.info('LocalNotificationService initialized');
  }

  Future<void> showInvitationNotification({
    required String invitationId,
    required String tripTitle,
    required String inviterName,
  }) async {
    if (!_initialized) {
      AppLogger.talker.warning(
        'LocalNotificationService not initialized, skipping notification',
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = invitationId.hashCode & 0x7FFFFFFF;

    await _plugin.show(
      id,
      'Trip Invitation',
      '$inviterName invited you to join "$tripTitle"',
      details,
      payload: invitationId,
    );

    AppLogger.talker.info(
      'Notification shown: invitation to "$tripTitle" from $inviterName',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    AppLogger.talker.info('Notification tapped with payload: $payload');

    _navigateToInvitations();
  }

  void _navigateToInvitations() {
    try {
      final router = _ref.read(appRouterProvider);
      router.push(RoutePaths.tripInvitations);
      AppLogger.talker.info('Navigated to invitations screen');
    } catch (e, st) {
      AppLogger.talker.error('Failed to navigate to invitations', e, st);
    }
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService(ref);
});
