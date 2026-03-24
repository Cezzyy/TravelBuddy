# TravelBuddy Configuration Setup

This document explains how to configure and run TravelBuddy with environment-specific settings.

## Quick Start

1. **Initial Setup**
   ```bash
   make setup
   ```
   This creates `config/dev.json`, `config/staging.json`, and `config/prod.json` from templates.

2. **Update Credentials**
   Edit the generated JSON files in the `config/` folder with your actual Firebase and Sentry credentials.

3. **Run the App**
   ```bash
   make run-dev      # Development
   make run-staging  # Staging
   make run-prod     # Production
   ```

## Configuration Architecture

### Two-Layer System

1. **External Layer** (`/config` folder)
   - JSON files containing environment-specific secrets
   - Git-ignored (except `.example` templates)
   - Files: `dev.json`, `staging.json`, `prod.json`

2. **Internal Layer** (`lib/config/app_config.dart`)
   - Dart class that reads from `String.fromEnvironment`
   - Values injected at compile-time via `--dart-define-from-file`
   - Type-safe access throughout the app

### How It Works

```
config/dev.json → --dart-define-from-file → String.fromEnvironment → AppConfig
```

## Configuration Files

### Structure

Each JSON file in `/config` should have platform-specific Firebase keys:

```json
{
  "FIREBASE_PROJECT_ID": "your-project-id",
  "FIREBASE_MESSAGING_SENDER_ID": "your-sender-id",
  "FIREBASE_STORAGE_BUCKET": "your-storage-bucket",
  "FIREBASE_AUTH_DOMAIN": "your-auth-domain",
  "FIREBASE_WEB_API_KEY": "your-web-api-key",
  "FIREBASE_WEB_APP_ID": "your-web-app-id",
  "FIREBASE_WEB_MEASUREMENT_ID": "your-web-measurement-id",
  "FIREBASE_ANDROID_API_KEY": "your-android-api-key",
  "FIREBASE_ANDROID_APP_ID": "your-android-app-id",
  "FIREBASE_IOS_API_KEY": "your-ios-api-key",
  "FIREBASE_IOS_APP_ID": "your-ios-app-id",
  "FIREBASE_IOS_BUNDLE_ID": "com.example.travelbuddy",
  "SENTRY_DSN": "your-sentry-dsn",
  "APP_NAME": "TravelBuddy Dev",
  "ENVIRONMENT": "development"
}
```

### Unified Config Approach

The `firebase_options.dart` file now reads from `AppConfig` instead of hardcoded values. This means:
- All Firebase credentials are managed in your JSON config files
- Platform-specific keys (Web, Android, iOS) are automatically selected at runtime
- You can easily switch between environments without regenerating Firebase options

### Environment Values

- `dev.json`: `ENVIRONMENT: "development"`
- `staging.json`: `ENVIRONMENT: "staging"`
- `prod.json`: `ENVIRONMENT: "production"`

## Usage in Code

```dart
import 'package:travelbuddy/config/app_config.dart';
import 'package:travelbuddy/firebase_options.dart';

// Initialize Firebase with unified config
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Access configuration
final projectId = AppConfig.firebaseProjectId;
final webApiKey = AppConfig.firebaseWebApiKey;
final androidApiKey = AppConfig.firebaseAndroidApiKey;

// Environment checks
if (AppConfig.isDevelopment) {
  print('Running in dev mode');
}

// Validation
if (!AppConfig.isConfigured) {
  throw Exception('App not properly configured!');
}

// Debug
AppConfig.printConfig();
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make setup` | Copy config templates and create actual config files |
| `make run-dev` | Run app with development config |
| `make run-staging` | Run app with staging config |
| `make run-prod` | Run app with production config (release mode) |
| `make build-dev` | Build APK with development config |
| `make build-staging` | Build APK with staging config |
| `make build-prod` | Build production APK |
| `make gen` | Run code generation (build_runner) |
| `make clean` | Clean build artifacts |

## Manual Commands (Without Make)

If you prefer not to use Make:

```bash
# Development
flutter run --dart-define-from-file=config/dev.json

# Staging
flutter run --dart-define-from-file=config/staging.json

# Production
flutter run --dart-define-from-file=config/prod.json --release
```

## Security Notes

- Never commit actual `config/*.json` files (only `.example` files)
- The `.gitignore` is configured to exclude secrets
- Share credentials securely with team members (use password managers, not Git)
- Rotate credentials if accidentally exposed

## Troubleshooting

### "Config not found" error
- Run `make setup` to create config files
- Ensure you've updated the JSON files with actual credentials

### Values are empty in app
- Check that JSON keys match exactly with `String.fromEnvironment` names
- Verify you're using `--dart-define-from-file` flag
- Try `flutter clean` and rebuild

### Make command not found (Windows)
- Install Make for Windows, or
- Use the manual Flutter commands listed above
