import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Hero banner with call-to-action for creating trips.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.onCreateTrip, this.imageUrl});

  final VoidCallback onCreateTrip;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      height: size.height * 0.42,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with gapless playback
            Image.asset(
              'assets/images/heroimage.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content positioned at bottom left
            Positioned(
              bottom: 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Plan your next\nadventure',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onCreateTrip,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Create new trip plan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
