/// Centralized route path and name constants.
/// Add new routes here as features are built.
abstract class RoutePaths {
  static const splash = '/';
  static const auth = '/auth';
  static const authEmail = '/auth/email';
  static const onboardingProfile = '/onboarding/profile';
  static const onboardingPreferences = '/onboarding/preferences';
  static const onboardingRules = '/onboarding/rules';
  static const home = '/home';
  static const tripDetail = '/trips/:tripId';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const auth = 'auth';
  static const authEmail = 'auth-email';
  static const onboardingProfile = 'onboarding-profile';
  static const onboardingPreferences = 'onboarding-preferences';
  static const onboardingRules = 'onboarding-rules';
  static const home = 'home';
  static const tripDetail = 'trip-detail';
}
