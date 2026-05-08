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
  static const trips = '/trips';
  static const guides = '/guides';
  static const profile = '/profile';
  static const tripDetail = '/trips/:tripId';
  static const createSelection = '/create';

  // Guide routes
  static const guideCreate = '/guides/create';
  static const guideDetail = '/guides/:guideId';
  static const guideEdit = '/guides/:guideId/edit';
  static const guideItinerary = '/guides/:guideId/itinerary';
  static const myGuides = '/guides/my';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const auth = 'auth';
  static const authEmail = 'auth-email';
  static const onboardingProfile = 'onboarding-profile';
  static const onboardingPreferences = 'onboarding-preferences';
  static const onboardingRules = 'onboarding-rules';
  static const home = 'home';
  static const trips = 'trips';
  static const guides = 'guides';
  static const profile = 'profile';
  static const tripDetail = 'trip-detail';
  static const createSelection = 'create-selection';

  // Guide routes
  static const guideCreate = 'guide-create';
  static const guideDetail = 'guide-detail';
  static const guideEdit = 'guide-edit';
  static const guideItinerary = 'guide-itinerary';
  static const myGuides = 'my-guides';
}
