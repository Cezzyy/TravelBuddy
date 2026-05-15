import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../logging/app_logger.dart';
import 'firestore_sync_service.dart';
import 'sync_queue_processor.dart';

/// Manages Firestore sync lifecycle based on authentication state.
///
/// When the user signs in:
/// 1. Starts real-time Firestore listeners (collaborative updates).
/// 2. Processes any pending items in the sync queue (offline retry).
///
/// When the user signs out:
/// 1. Stops all Firestore listeners to avoid leaks.
///
/// Watch this provider to keep the sync lifecycle alive.
/// It automatically reacts to auth state changes.
final syncLifecycleProvider = Provider<SyncLifecycleManager>((ref) {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  final queueProcessor = ref.watch(syncQueueProcessorProvider);

  final manager = SyncLifecycleManager(syncService, queueProcessor);

  // Watch auth state stream to auto start/stop sync
  ref.listen(authStateProvider, (_, next) {
    next.whenData((user) {
      if (user != null) {
        AppLogger.talker.info('SyncLifecycle: User signed in (${user.uid})');
        // Fire and forget — startListeners is synchronous,
        // processPending runs asynchronously in background
        manager.onSignIn(user);
      } else {
        AppLogger.talker.info('SyncLifecycle: User signed out');
        manager.onSignOut();
      }
    });
  });

  // Clean up on dispose
  ref.onDispose(() {
    manager.onSignOut();
  });

  return manager;
});

/// Imperative manager for Firestore sync lifecycle.
///
/// Created by [syncLifecycleProvider] and can also be used directly
/// from auth state callbacks if needed.
class SyncLifecycleManager {
  SyncLifecycleManager(this._syncService, this._queueProcessor);

  final FirestoreSyncService _syncService;
  final SyncQueueProcessor _queueProcessor;

  /// Start all sync services for the given user.
  Future<void> onSignIn(auth.User user) async {
    AppLogger.talker.info('SyncLifecycleManager: onSignIn for ${user.uid}');

    _syncService.startListeners();

    try {
      await _queueProcessor.processPending();
    } catch (e, st) {
      AppLogger.talker.error(
        'SyncLifecycleManager: Failed to process sync queue',
        e,
        st,
      );
    }
  }

  /// Stop all sync services (call on sign-out).
  void onSignOut() {
    AppLogger.talker.info('SyncLifecycleManager: onSignOut');
    _syncService.stopListeners();
  }

  /// Manually trigger queue processing (e.g., on connectivity restore).
  Future<int> processQueue() async {
    return await _queueProcessor.processPending();
  }

  /// Clean up old completed/failed items from the sync queue.
  Future<void> cleanupQueue({
    Duration olderThan = const Duration(days: 7),
  }) async {
    await _queueProcessor.cleanup(olderThan: olderThan);
  }
}
