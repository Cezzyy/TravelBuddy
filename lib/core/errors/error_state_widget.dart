import 'package:flutter/material.dart';

import '../errors/app_exceptions.dart';
import '../theme/app_colors.dart';

/// Reusable error state widget with icon, message, and optional retry.
///
/// Use this instead of ad-hoc error widgets to ensure consistent error UX
/// across the app. Displays a user-friendly message from [AppException]
/// or falls back to a generic message for unknown errors.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.isOffline = false,
    super.key,
  });

  /// Create from an [AppException] — extracts the user message automatically.
  factory ErrorStateWidget.fromException(
    Object error, {
    VoidCallback? onRetry,
    Key? key,
  }) {
    final appException = error is AppException
        ? error
        : convertException(error);

    final isOffline =
        appException is NetworkException && appException.isOffline;

    return ErrorStateWidget(
      message: appException.userMessage,
      onRetry: onRetry,
      isOffline: isOffline,
      key: key,
    );
  }

  /// The user-facing error message.
  final String message;

  /// Icon to display above the message.
  final IconData icon;

  /// Optional retry callback. When provided, a "Retry" button is shown.
  final VoidCallback? onRetry;

  /// Whether this is an offline error (shows wifi icon instead of error icon).
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final displayIcon = isOffline ? Icons.wifi_off_rounded : icon;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isOffline ? AppColors.warning : AppColors.error)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon,
                size: 48,
                color: isOffline ? AppColors.warning : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isOffline ? 'No Connection' : 'Something Went Wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Retry'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline error widget for use inside lists, cards, etc.
class InlineErrorWidget extends StatelessWidget {
  const InlineErrorWidget({
    required this.message,
    this.onRetry,
    this.isOffline = false,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isOffline ? AppColors.warning : AppColors.error).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isOffline ? AppColors.warning : AppColors.error).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 20,
            color: isOffline ? AppColors.warning : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOffline ? AppColors.warning : AppColors.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// SnackBar helper for showing errors consistently across the app.
class AppErrorSnackBar {
  AppErrorSnackBar._();

  static void show(BuildContext context, Object error) {
    final appException = error is AppException
        ? error
        : convertException(error);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appException.userMessage),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showOffline(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You\'re offline. Some features may be limited.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSyncFailed(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Changes saved locally. Will sync when you\'re back online.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
