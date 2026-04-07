import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/user_repository.dart';
import '../../domain/onboarding_step.dart';

final onboardingStatusProvider = StreamProvider<OnboardingStep>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  final firebaseUser = authRepo.currentUser;
  if (firebaseUser == null) {
    return Stream.value(OnboardingStep.profile);
  }

  final uid = firebaseUser.uid;

  return userRepo.watchLocalUser(uid).asyncExpand((user) {
    if (user == null) {
      return const Stream.empty();
    }
    return userRepo
        .watchUserPreferences(uid)
        .map((prefs) => resolveOnboardingStep(user: user, preferences: prefs));
  });
});
