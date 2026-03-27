import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging/app_logger.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import 'placeholder_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// Shared fade transition for smooth screen changes.
CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 500),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    observers: [TalkerRouteObserver(AppLogger.talker)],

    // TODO: Add redirect logic in Step 2 (Auth) based on auth state + onboarding flags.
    // redirect: (context, state) { ... },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.auth,
        name: RouteNames.auth,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const AuthScreen()),
        routes: [
          GoRoute(
            path: 'email',
            name: RouteNames.authEmail,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const EmailAuthScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final slide =
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return SlideTransition(position: slide, child: child);
                  },
            ),
          ),
        ],
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
        builder: (context, state) => const PlaceholderScreen(title: 'Home'),
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
