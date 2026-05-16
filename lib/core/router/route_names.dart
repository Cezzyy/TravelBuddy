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
  static const createSelection = '/create';

  // Trip routes
  static const tripCreate = '/trips/create';
  static const tripDetail = '/trips/:tripId';
  static const tripEdit = '/trips/:tripId/edit';
  static const tripItinerary = '/trips/:tripId/itinerary';

  // Guide routes
  static const guideCreate = '/guides/create';
  static const guideDetail = '/guides/:guideId';
  static const guideEdit = '/guides/:guideId/edit';
  static const guideItinerary = '/guides/:guideId/itinerary';
  static const myGuides = '/guides/my';

  // Profile routes
  static const travelPreferences = '/profile/travel-preferences';
  static const editProfile = '/profile/edit';

  // Notification routes
  static const notifications = '/notifications';

  // Trip invitation routes (legacy — kept for reference)
  static const tripInvitations = '/trips/invitations';
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
  static const createSelection = 'create-selection';

  // Trip routes
  static const tripCreate = 'trip-create';
  static const tripDetail = 'trip-detail';
  static const tripEdit = 'trip-edit';
  static const tripItinerary = 'trip-itinerary';

  // Guide routes
  static const guideCreate = 'guide-create';
  static const guideDetail = 'guide-detail';
  static const guideEdit = 'guide-edit';
  static const guideItinerary = 'guide-itinerary';
  static const myGuides = 'my-guides';

  // Profile routes
  static const travelPreferences = 'travel-preferences';
  static const editProfile = 'edit-profile';

  // Notification routes
  static const notifications = 'notifications';

  // Trip invitation routes (legacy — kept for reference)
  static const tripInvitations = 'trip-invitations';
}
