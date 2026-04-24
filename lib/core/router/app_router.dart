import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../logging/app_logger.dart';
import '../layout/main_shell_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/create/presentation/create_selection_screen.dart';
import '../../features/guides/presentation/guides_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/domain/onboarding_step.dart';
import '../../features/onboarding/presentation/preferences_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/rules_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// Helper class to refresh GoRouter when a stream emits.
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

/// Helper class to refresh GoRouter when Riverpod provider state changes.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(
    Ref ref,
    List<ProviderListenable> providers, {
    Stream<dynamic>? stream,
  }) {
    for (final provider in providers) {
      ref.listen(provider, (_, _) => notifyListeners());
    }

    if (stream != null) {
      notifyListeners();
      _subscription = stream.listen((_) => notifyListeners());
    }
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Shared fade transition for smooth screen changes.
CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 400),
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
  final onboardingAsync = ref.watch(onboardingStatusProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    observers: [TalkerRouteObserver(AppLogger.talker)],
    refreshListenable: GoRouterRefreshNotifier(ref, [
      currentUserProvider,
      onboardingStatusProvider,
    ], stream: authRepo.authStateChanges()),

    redirect: (context, state) {
      final firebaseUser = authRepo.currentUser;
      final isAuthenticated = firebaseUser != null;
      final location = state.matchedLocation;
      final isOnSplash = location == RoutePaths.splash;
      final isOnAuth = location.startsWith(RoutePaths.auth);
      final isOnOnboarding = location.startsWith('/onboarding');

      AppLogger.talker.debug(
        'Router redirect: location=$location, authenticated=$isAuthenticated',
      );

      // Not authenticated - redirect to auth
      if (!isAuthenticated) {
        if (isOnAuth) {
          return null;
        }
        AppLogger.talker.debug('Redirecting to auth (not authenticated)');
        return RoutePaths.auth;
      }

      // Authenticated but onboarding status is loading - stay on splash
      if (onboardingAsync.isLoading) {
        if (isOnSplash) {
          return null;
        }
        AppLogger.talker.debug('Redirecting to splash (onboarding loading)');
        return RoutePaths.splash;
      }

      // Onboarding provider error - log and allow navigation
      if (onboardingAsync.hasError) {
        AppLogger.talker.error(
          'Onboarding provider error: ${onboardingAsync.error}',
          onboardingAsync.error,
          onboardingAsync.stackTrace,
        );
        // Don't block navigation on error, let user proceed
        return null;
      }

      final step = onboardingAsync.value!;
      AppLogger.talker.debug('Current onboarding step: $step');

      // User needs to complete onboarding
      if (step != OnboardingStep.complete) {
        final target = switch (step) {
          OnboardingStep.profile => RoutePaths.onboardingProfile,
          OnboardingStep.preferences => RoutePaths.onboardingPreferences,
          OnboardingStep.rules => RoutePaths.onboardingRules,
          OnboardingStep.complete => RoutePaths.home,
        };

        if (location != target) {
          AppLogger.talker.debug('Redirecting to onboarding: $target');
          return target;
        }
        return null;
      }

      // Onboarding complete - redirect away from splash/auth/onboarding
      if (isOnSplash || isOnAuth || isOnOnboarding) {
        AppLogger.talker.debug('Redirecting to home (onboarding complete)');
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

      // Auth
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
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingPreferences,
        name: RouteNames.onboardingPreferences,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const PreferencesScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingRules,
        name: RouteNames.onboardingRules,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(key: state.pageKey, child: const RulesScreen()),
      ),

      // Create Selection (Modal)
      GoRoute(
        path: RoutePaths.createSelection,
        name: RouteNames.createSelection,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CreateSelectionScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                pageBuilder: (context, state) => _fadeTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.trips,
                name: RouteNames.trips,
                builder: (context, state) => const TripsScreen(),
                // TODO: Add trip detail route when screen is implemented
                // routes: [
                //   GoRoute(
                //     path: ':tripId',
                //     name: RouteNames.tripDetail,
                //     builder: (context, state) {
                //       final tripId = state.pathParameters['tripId']!;
                //       return TripDetailScreen(tripId: tripId);
                //     },
                //   ),
                // ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.guides,
                name: RouteNames.guides,
                builder: (context, state) => const GuidesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
