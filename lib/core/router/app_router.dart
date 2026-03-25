import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging/app_logger.dart';
import 'placeholder_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    observers: [
      TalkerRouteObserver(AppLogger.talker),
    ],

    // TODO: Add redirect logic in Step 2 (Auth) based on auth state + onboarding flags.
    // redirect: (context, state) { ... },

    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Splash'),
      ),
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.auth,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Auth'),
      ),
      GoRoute(
        path: RoutePaths.onboardingProfile,
        name: RouteNames.onboardingProfile,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Profile Setup'),
      ),
      GoRoute(
        path: RoutePaths.onboardingPreferences,
        name: RouteNames.onboardingPreferences,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Preferences'),
      ),
      GoRoute(
        path: RoutePaths.onboardingRules,
        name: RouteNames.onboardingRules,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Rules & Regulations'),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: RoutePaths.tripDetail,
        name: RouteNames.tripDetail,
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return PlaceholderScreen(title: 'Trip: $tripId');
        },
      ),
    ],
  );
}
