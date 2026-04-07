import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/current_user_provider.dart';

/// Profile screen — shows user info, preferences, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return localUser.when(
      data: (user) => _buildContent(context, user, theme, colors),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic user,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Traveler',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Settings cards
          _SettingsCard(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your name and photo',
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.tune_rounded,
            title: 'Travel Preferences',
            subtitle: 'Adjust your travel style and interests',
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.shield_outlined,
            title: 'Privacy & Security',
            subtitle: 'Account security and data settings',
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'App version and legal info',
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
