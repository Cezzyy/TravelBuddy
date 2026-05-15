import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// Monitors device connectivity state and exposes it as a Riverpod stream.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  bool isOffline(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.none);
}

/// Provider for the connectivity service (keep-alive since we always need it).
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

/// Stream provider that emits true when the device goes offline.
/// Subscribes to connectivity changes and filters for offline state.
final isOfflineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);

  // Emit current state first
  return service.onConnectivityChanged.map((results) {
    final offline = results.contains(ConnectivityResult.none);
    if (offline) {
      AppLogger.talker.warning('Device went offline');
    } else {
      AppLogger.talker.info('Device is online: $results');
    }
    return offline;
  });
});
