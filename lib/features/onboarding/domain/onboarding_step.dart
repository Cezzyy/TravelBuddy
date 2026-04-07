import '../../../shared/data/app_db.dart';

enum OnboardingStep { profile, preferences, rules, complete }

OnboardingStep resolveOnboardingStep({
  required User user,
  required UserPreference? preferences,
}) {
  if (!user.isProfileComplete) {
    return OnboardingStep.profile;
  }
  if (preferences == null) {
    return OnboardingStep.preferences;
  }
  if (!user.hasAgreedToRules) {
    return OnboardingStep.rules;
  }
  return OnboardingStep.complete;
}
