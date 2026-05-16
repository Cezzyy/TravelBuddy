# TravelBuddy

A modern Flutter application for planning trips, creating travel guides, and collaborating with fellow travelers. Built with an offline-first architecture and real-time synchronization.

## Features

### Trip Planning
- Create and manage personal trips with detailed itineraries
- Add day-by-day activities with times, locations, and notes
- Collaborate with other travelers in real-time
- Invite friends via email to join your trips
- Track trip status (planning, ongoing, completed)

### Travel Guides
- Browse community-created travel guides
- Create and publish your own guides
- Draft versioning system for safe editing of published guides
- Like and comment on guides
- Reference guides in your trips for easy planning
- Filter guides by destination and category

### Collaboration
- Real-time trip collaboration with multiple users
- Role-based permissions (owner, editor, viewer)
- Trip invitation system with accept/decline functionality
- See who's collaborating on your trips

### Offline-First Architecture
- Full offline functionality with local SQLite database
- Automatic sync when connection is restored
- Conflict resolution for concurrent edits
- Works seamlessly with or without internet

### Notifications
- Local notifications for trip reminders
- Invitation notifications
- Activity updates from collaborators

### User Profile
- Google Sign-In authentication
- Customizable profile with display name and bio
- Profile picture support
- View your trips and published guides

## Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management with code generation
- **GoRouter** - Declarative routing

### Backend & Database
- **Firebase Auth** - User authentication with Google Sign-In
- **Cloud Firestore** - Real-time cloud database
- **Drift** - Type-safe SQLite ORM for offline storage
- **SQLite** - Local database for offline-first functionality

### Architecture
- **Clean Architecture** - Feature-based modular structure
- **Offline-First** - Local database with cloud sync
- **Repository Pattern** - Data layer abstraction
- **Provider Pattern** - State management with Riverpod

### Development Tools
- **Build Runner** - Code generation for Riverpod and Drift
- **Talker** - Logging and debugging
- **Sentry** - Error tracking and monitoring
- **Flutter Lints** - Code quality and style enforcement

## Project Structure

```
lib/
├── config/              # App configuration
├── core/                # Core functionality
│   ├── logging/         # Logging setup
│   ├── notifications/   # Local notifications
│   ├── router/          # Navigation and routing
│   ├── sync/            # Firestore sync logic
│   └── theme/           # App theming
├── features/            # Feature modules
│   ├── auth/            # Authentication
│   ├── create/          # Create trip/guide flow
│   ├── guides/          # Travel guides feature
│   ├── home/            # Home screen
│   ├── notifications/   # Notifications screen
│   ├── onboarding/      # Onboarding flow
│   ├── profile/         # User profile
│   └── trips/           # Trip planning feature
├── shared/              # Shared code
│   ├── data/            # Database and models
│   └── widgets/         # Reusable widgets
├── app.dart             # Root app widget
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (^3.11.0)
- Dart SDK
- Firebase project with:
  - Authentication enabled (Google Sign-In)
  - Cloud Firestore database
  - Firebase configuration files

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TravelBuddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` (Android) to `android/app/`
   - Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Configure Sentry (Optional)**
   - Update `lib/config/app_config.dart` with your Sentry DSN
   - Or leave empty to disable error tracking

5. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## Database Schema

The app uses a hybrid database approach:
- **Local**: SQLite via Drift for offline-first functionality
- **Cloud**: Firestore for real-time sync and collaboration

### Current Schema Version: v3

Key tables:
- `users` - User profiles and authentication
- `trips` - Trip information and metadata
- `itinerary_items` - Day-by-day trip activities
- `trip_collaborators` - Trip sharing and permissions
- `trip_invitations` - Pending trip invitations
- `guides` - Published and draft travel guides
- `guide_itinerary_items` - Guide content and activities
- `guide_likes` - User likes on guides
- `guide_comments` - Comments on guides
- `trip_guide_references` - Links between trips and guides

See [docs/database-schema-v3.md](docs/database-schema-v3.md) for detailed schema documentation.

## Development

### Code Generation

The project uses code generation for:
- Riverpod providers (`riverpod_generator`)
- Drift database tables and DAOs (`drift_dev`)

Run code generation:
```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Firestore Security Rules

Security rules are defined in `firestore.rules`. Deploy them using:
```bash
firebase deploy --only firestore:rules
```

### Logging

The app uses Talker for comprehensive logging:
- View logs in the console during development
- Access in-app log viewer via the profile screen
- Logs are automatically sent to Sentry in production

### Testing

Run tests:
```bash
flutter test
```

## Key Features Implementation

### Offline-First Sync
- All data is stored locally in SQLite using Drift
- Changes are automatically synced to Firestore when online
- Firestore listeners update local database in real-time
- Conflict resolution handles concurrent edits

### Draft Versioning for Guides
- Published guides can be edited without affecting live content
- System creates a draft version when editing published guides
- Preview changes before applying them
- Discard unwanted changes without affecting published version

### Real-Time Collaboration
- Multiple users can collaborate on the same trip
- Changes sync in real-time via Firestore
- Role-based permissions (owner, editor, viewer)
- Invitation system with email notifications

## Configuration

### App Configuration
Edit `lib/config/app_config.dart`:
- App name and version
- Environment (development/production)
- Sentry DSN for error tracking
- Feature flags

### Firebase Configuration
- Authentication providers in Firebase Console
- Firestore security rules in `firestore.rules`
- Cloud Functions (if needed) in `functions/`

---
