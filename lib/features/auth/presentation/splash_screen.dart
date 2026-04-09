import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Splash screen shown while the onboarding provider resolves.
/// Contains no navigation logic — the router redirect handles that.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Icon(
          Icons.mode_of_travel_rounded,
          color: AppColors.primary,
          size: 80,
        ),
      ),
    );
  }
}
