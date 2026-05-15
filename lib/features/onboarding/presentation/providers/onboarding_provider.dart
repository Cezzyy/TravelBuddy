import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/onboarding_step.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple onboarding provider that watches Firestore for real-time updates
/// Automatically navigates when user completes each onboarding step
final onboardingStatusProvider = StreamProvider<OnboardingStep>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final firestore = FirebaseFirestore.instance;

  await for (final firebaseUser in authRepo.authStateChanges()) {
    if (firebaseUser == null) {
      AppLogger.talker.debug('No Firebase user');
      yield OnboardingStep.profile;
      continue;
    }

    final uid = firebaseUser.uid;
    AppLogger.talker.debug('Watching onboarding status for user: $uid');

    try {
      // Watch user document for real-time updates
      await for (final docSnapshot
          in firestore.collection('users').doc(uid).snapshots()) {
        if (!docSnapshot.exists) {
          // New user - needs to complete profile
          AppLogger.talker.info('New user, needs profile setup');
          yield OnboardingStep.profile;
          continue;
        }

        final data = docSnapshot.data()!;
        final isProfileComplete = data['isProfileComplete'] as bool? ?? false;
        final hasPreferences = data['preferences'] != null;
        final hasAgreedToRules = data['hasAgreedToRules'] as bool? ?? false;

        // Determine onboarding step
        if (!isProfileComplete) {
          AppLogger.talker.debug('User needs to complete profile');
          yield OnboardingStep.profile;
        } else if (!hasPreferences) {
          AppLogger.talker.debug('User needs to set preferences');
          yield OnboardingStep.preferences;
        } else if (!hasAgreedToRules) {
          AppLogger.talker.debug('User needs to agree to rules');
          yield OnboardingStep.rules;
        } else {
          AppLogger.talker.debug('User onboarding complete');
          yield OnboardingStep.complete;
        }
      }
    } catch (e, st) {
      AppLogger.talker.error('Error watching onboarding status', e, st);
      throw convertException(e);
    }
  }
});
