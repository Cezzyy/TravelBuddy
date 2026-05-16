/// Base class for all app-specific exceptions.
class AppException implements Exception {
  final String userMessage;
  final String? technicalDetails;
  final Exception? originalException;

  const AppException({
    required this.userMessage,
    this.technicalDetails,
    this.originalException,
  });

  @override
  String toString() => technicalDetails ?? userMessage;
}

// ─── Network ────────────────────────────────────────────────────────────────

class NetworkException extends AppException {
  final bool isOffline;

  const NetworkException({
    String? userMessage,
    this.isOffline = false,
    super.technicalDetails,
    super.originalException,
  }) : super(
         userMessage:
             userMessage ??
             (isOffline
                 ? 'You appear to be offline. Check your connection and try again.'
                 : 'A network error occurred. Please try again.'),
       );
}

// ─── Authentication ──────────────────────────────────────────────────────────

class AuthException extends AppException {
  final AuthErrorType errorType;

  AuthException({
    required this.errorType,
    String? userMessage,
    super.technicalDetails,
    super.originalException,
  }) : super(userMessage: userMessage ?? errorType.userMessage);
}

enum AuthErrorType {
  invalidCredentials('The email or password is incorrect. Please try again.'),
  emailAlreadyInUse(
    'This email is already registered. Try signing in instead.',
  ),
  weakPassword('Please choose a stronger password with at least 6 characters.'),
  userNotFound('We couldn\'t find an account with this email.'),
  userDisabled('This account is no longer active. Contact support for help.'),
  tooManyRequests(
    'Too many failed attempts. Please wait a few minutes and try again.',
  ),
  networkError('Connection problem. Check your internet and try again.'),
  googleSignInFailed('Google sign-in didn\'t complete. Please try again.'),
  signOutFailed('Something went wrong signing out. Please try again.'),
  unknown('Something went wrong. Please try again.');

  final String userMessage;
  const AuthErrorType(this.userMessage);
}

// ─── Data / Sync ──────────────────────────────────────────────────────────────

class SyncException extends AppException {
  final SyncErrorType errorType;

  SyncException({
    required this.errorType,
    String? userMessage,
    super.technicalDetails,
    super.originalException,
  }) : super(userMessage: userMessage ?? errorType.userMessage);
}

enum SyncErrorType {
  writeFailed(
    'Changes could not be saved. They will be retried automatically.',
  ),
  readFailed('Could not load the latest data. Showing cached version.'),
  conflictFailed('Your changes conflict with newer data. Please refresh.'),
  queueFailed(
    'Some changes are pending sync and will be sent when you\'re back online.',
  ),
  unknown('A sync error occurred. Your data is saved locally.');

  final String userMessage;
  const SyncErrorType(this.userMessage);
}

// ─── Data Access ──────────────────────────────────────────────────────────────

class DataException extends AppException {
  final DataErrorType errorType;

  DataException({
    required this.errorType,
    String? userMessage,
    super.technicalDetails,
    super.originalException,
  }) : super(userMessage: userMessage ?? errorType.userMessage);
}

enum DataErrorType {
  notFound('The requested item could not be found.'),
  permissionDenied('You don\'t have permission to access this.'),
  validationFailed('Some information is invalid. Please check and try again.'),
  databaseError('A local database error occurred. Please restart the app.'),
  unknown('An error occurred while loading data.');

  final String userMessage;
  const DataErrorType(this.userMessage);
}

// ─── Helper: Convert raw exceptions ──────────────────────────────────────────

/// Converts a raw exception into a user-friendly [AppException].
AppException convertException(Object error) {
  if (error is AppException) return error;

  final errorString = error.toString().toLowerCase();

  // Network patterns
  if (errorString.contains('socket') ||
      errorString.contains('network') ||
      errorString.contains('connection') ||
      errorString.contains('timeout') ||
      errorString.contains('host')) {
    return NetworkException(
      originalException: error is Exception ? error : null,
    );
  }

  // Firestore patterns
  if (errorString.contains('permission-denied') ||
      errorString.contains('permission_denied')) {
    return DataException(
      errorType: DataErrorType.permissionDenied,
      originalException: error is Exception ? error : null,
    );
  }

  if (errorString.contains('not-found') || errorString.contains('not_found')) {
    return DataException(
      errorType: DataErrorType.notFound,
      originalException: error is Exception ? error : null,
    );
  }

  // Default
  return AppException(
    userMessage: 'An unexpected error occurred. Please try again.',
    technicalDetails: error.toString(),
    originalException: error is Exception ? error : null,
  );
}
