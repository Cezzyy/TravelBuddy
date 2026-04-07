import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging/app_logger.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/domain/onboarding_step.dart';
import '../../features/onboarding/presentation/preferences_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/rules_screen.dart';
import 'placeholder_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// Helper class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    observers: [TalkerRouteObserver(AppLogger.talker)],
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),

    // Redirect logic based on auth state
    redirect: (context, state) async {
      final firebaseUser = authRepo.currentUser;
      final isAuthenticated = firebaseUser != null;
      final matchedLocation = state.matchedLocation;
      final isOnAuth = matchedLocation.startsWith(RoutePaths.auth);
      final isOnOnboarding = matchedLocation.startsWith('/onboarding');

      if (!isAuthenticated) {
        if (isOnAuth || matchedLocation == RoutePaths.splash) {
          return null;
        }
        AppLogger.talker.debug('Redirecting to auth: user not authenticated');
        return RoutePaths.auth;
      }

      final localUser =
          await userRepo.getLocalUser(firebaseUser.uid) ??
          await userRepo.syncUserFromAuth(firebaseUser);
      final preferences = await userRepo.getUserPreferences(firebaseUser.uid);
      final onboardingStep = resolveOnboardingStep(
        user: localUser,
        preferences: preferences,
      );

      if (onboardingStep != OnboardingStep.complete) {
        final onboardingPath = switch (onboardingStep) {
          OnboardingStep.profile => RoutePaths.onboardingProfile,
          OnboardingStep.preferences => RoutePaths.onboardingPreferences,
          OnboardingStep.rules => RoutePaths.onboardingRules,
          OnboardingStep.complete => RoutePaths.home,
        };
        if (matchedLocation != onboardingPath) {
          AppLogger.talker.debug(
            'Redirecting to onboarding step: $onboardingPath',
          );
          return onboardingPath;
        }
        return null;
      }

      if (matchedLocation == RoutePaths.splash || isOnAuth || isOnOnboarding) {
        AppLogger.talker.debug('Redirecting to home: onboarding completed');
        return RoutePaths.home;
      }

      return null;
    },
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
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingPreferences,
        name: RouteNames.onboardingPreferences,
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingRules,
        name: RouteNames.onboardingRules,
        builder: (context, state) => const RulesScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
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
