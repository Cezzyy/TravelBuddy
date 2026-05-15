import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/providers/current_user_provider.dart';
import '../../auth/presentation/providers/firestore_user_provider.dart';
import 'providers/profile_stats_provider.dart';
import 'edit_profile_screen.dart';

/// Profile screen — shows user info, travel stats, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreUser = ref.watch(firestoreUserProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Debug logging
    AppLogger.talker.debug(
      'Profile screen build - Firestore: ${firestoreUser.hasValue ? firestoreUser.value?.id : 'loading'}, Local: ${currentUser.hasValue ? currentUser.value?.id : 'loading'}',
    );

    return firestoreUser.when(
      data: (user) {
        AppLogger.talker.debug(
          'Profile screen - Firestore user: ${user?.id} (${user?.email})',
        );

        // If Firestore user is null but we have a current user, show loading
        // This handles the case where user just switched accounts
        if (user == null && currentUser.hasValue && currentUser.value != null) {
          AppLogger.talker.debug(
            'Profile screen - Showing loading (Firestore null, local exists)',
          );
          return const Center(child: CircularProgressIndicator());
        }

        // If both are null, show empty state
        if (user == null) {
          AppLogger.talker.debug('Profile screen - No user data available');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'No user data available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return _ProfileContent(user: user, localUser: currentUser.value);
      },
      loading: () {
        AppLogger.talker.debug('Profile screen - Loading Firestore user');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) {
        AppLogger.talker.error('Profile screen - Firestore error: $error');
        return Center(child: Text('Error: $error'));
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user, this.localUser});

  final dynamic user;
  final dynamic localUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Add debug logging to track user data changes
    ref.listen(firestoreUserProvider, (previous, next) {
      next.whenData((user) {
        AppLogger.talker.debug(
          'Profile screen - Firestore user changed: ${user?.id} (${user?.email})',
        );
      });
    });

    return CustomScrollView(
      slivers: [
        // Header with gradient
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Avatar with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Traveler',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatJoinDate(user?.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),

        // Travel Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _TravelStatsCard(),
          ),
        ),

        // Guide Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _GuideStatsCard(),
          ),
        ),

        // Account Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Account',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Edit Profile',
                subtitle: 'Update your display name',
                onTap: () => _navigateToEditProfile(context),
              ),
              const SizedBox(height: 8),
              _MenuTile(
                icon: Icons.favorite_outline_rounded,
                iconColor: AppColors.accent,
                title: 'Travel Preferences',
                subtitle: 'Your travel style and interests',
                onTap: () => _comingSoon(context),
              ),
              const SizedBox(height: 32),
              // Sign Out Button
              _SignOutButton(onPressed: () => _handleSignOut(context, ref)),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  String _formatJoinDate(DateTime? createdAt) {
    if (createdAt == null) return 'Joined recently';

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return 'Joined ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming Soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.logout_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(emailAuthControllerProvider.notifier).signOut();
    }
  }
}

class _TravelStatsCard extends ConsumerWidget {
  const _TravelStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripStatsAsync = ref.watch(userTripStatsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: tripStatsAsync.when(
        data: (tripStats) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.flight_takeoff_rounded,
                value: '${tripStats.tripCount}',
                label: 'Trips',
              ),
              const _VerticalDivider(),
              _StatItem(
                icon: Icons.location_on_outlined,
                value: '${tripStats.placesCount}',
                label: 'Places',
              ),
              const _VerticalDivider(),
              _StatItem(
                icon: Icons.calendar_today_outlined,
                value: '${tripStats.totalDays}',
                label: 'Days',
              ),
            ],
          );
        },
        loading: () => const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.flight_takeoff_rounded,
              value: '...',
              label: 'Trips',
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.location_on_outlined,
              value: '...',
              label: 'Places',
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.calendar_today_outlined,
              value: '...',
              label: 'Days',
            ),
          ],
        ),
        error: (_, _) => const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.flight_takeoff_rounded,
              value: '0',
              label: 'Trips',
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.location_on_outlined,
              value: '0',
              label: 'Places',
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.calendar_today_outlined,
              value: '0',
              label: 'Days',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStatsCard extends ConsumerWidget {
  const _GuideStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideStatsAsync = ref.watch(userGuideStatsProvider);
    final theme = Theme.of(context);

    return guideStatsAsync.when(
      data: (guideStats) {
        // Only show if user has guides
        if (guideStats.totalGuides == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Guide Stats',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStatItem(
                    value: '${guideStats.totalGuides}',
                    label: 'Guides',
                  ),
                  _MiniStatItem(
                    value: '${guideStats.publishedGuides}',
                    label: 'Published',
                  ),
                  _MiniStatItem(
                    value: '${guideStats.totalLikes}',
                    label: 'Likes',
                  ),
                  _MiniStatItem(
                    value: '${guideStats.totalViews}',
                    label: 'Views',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  const _MiniStatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textSecondary.withValues(alpha: 0.2),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
