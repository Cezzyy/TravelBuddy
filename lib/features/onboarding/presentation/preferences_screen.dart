import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../../../core/router/route_names.dart';

class _TravelStyleOption {
  const _TravelStyleOption(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

class _BudgetOption {
  const _BudgetOption(this.label, this.icon, this.hint);
  final String label;
  final IconData icon;
  final String hint;
}

class _ActivityOption {
  const _ActivityOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  static const _travelStyles = [
    _TravelStyleOption(
      'Adventure',
      Icons.terrain_rounded,
      'Thrilling experiences & outdoor exploration',
    ),
    _TravelStyleOption(
      'Relaxation',
      Icons.spa_rounded,
      'Unwind at resorts, spas & serene spots',
    ),
    _TravelStyleOption(
      'Cultural',
      Icons.account_balance_rounded,
      'History, art & local traditions',
    ),
    _TravelStyleOption(
      'Foodie',
      Icons.restaurant_rounded,
      'Culinary tours & local cuisine',
    ),
    _TravelStyleOption(
      'Backpacking',
      Icons.hiking_rounded,
      'Budget-friendly & off the beaten path',
    ),
    _TravelStyleOption(
      'Luxury',
      Icons.diamond_rounded,
      'Premium stays & exclusive experiences',
    ),
  ];

  static const _budgetLevels = [
    _BudgetOption('Budget', Icons.savings_rounded, 'Hostels & street food'),
    _BudgetOption(
      'Mid-range',
      Icons.account_balance_wallet_rounded,
      'Comfortable stays & dining',
    ),
    _BudgetOption(
      'Luxury',
      Icons.workspace_premium_rounded,
      'Top-tier everything',
    ),
  ];

  static const _activities = [
    _ActivityOption('Hiking', Icons.terrain_rounded),
    _ActivityOption('Beach', Icons.beach_access_rounded),
    _ActivityOption('Museums', Icons.museum_rounded),
    _ActivityOption('Nightlife', Icons.nightlife_rounded),
    _ActivityOption('Road Trips', Icons.directions_car_rounded),
    _ActivityOption('Local Food', Icons.ramen_dining_rounded),
    _ActivityOption('Photography', Icons.camera_alt_rounded),
    _ActivityOption('Shopping', Icons.shopping_bag_rounded),
    _ActivityOption('Water Sports', Icons.surfing_rounded),
    _ActivityOption('Wildlife', Icons.pets_rounded),
    _ActivityOption('Festivals', Icons.celebration_rounded),
    _ActivityOption('Wellness', Icons.self_improvement_rounded),
  ];

  String? _selectedTravelStyle;
  String? _selectedBudgetLevel;
  final Set<String> _selectedActivities = {};
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedTravelStyle == null || _selectedBudgetLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a travel style and budget level'),
        ),
      );
      return;
    }

    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one activity')),
      );
      return;
    }

    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) {
      if (mounted) context.goNamed(RouteNames.auth);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUserPreferences(
            userId: firebaseUser.uid,
            travelStyle: _selectedTravelStyle,
            budgetLevel: _selectedBudgetLevel,
            preferredActivities: jsonEncode(_selectedActivities.toList()),
          );
      if (mounted) {
        context.goNamed(RouteNames.onboardingRules);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Preferences')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Do You Like to Travel?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We\'ll tailor trip suggestions based on your style.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Travel Style ---
                    _SectionHeader(
                      icon: Icons.explore_rounded,
                      label: 'Travel Style',
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _travelStyles.map((style) {
                        final isSelected = _selectedTravelStyle == style.label;
                        return _SelectableCard(
                          icon: style.icon,
                          label: style.label,
                          subtitle: style.description,
                          isSelected: isSelected,
                          onTap: () => setState(
                            () => _selectedTravelStyle = style.label,
                          ),
                          colors: colors,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // --- Budget Level ---
                    _SectionHeader(
                      icon: Icons.payments_rounded,
                      label: 'Budget Level',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _budgetLevels.map((budget) {
                        final isSelected = _selectedBudgetLevel == budget.label;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: budget != _budgetLevels.last ? 10 : 0,
                            ),
                            child: _BudgetCard(
                              icon: budget.icon,
                              label: budget.label,
                              hint: budget.hint,
                              isSelected: isSelected,
                              onTap: () => setState(
                                () => _selectedBudgetLevel = budget.label,
                              ),
                              colors: colors,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // --- Activities ---
                    _SectionHeader(
                      icon: Icons.local_activity_rounded,
                      label: 'Favourite Activities',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick all that you enjoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _activities.map((activity) {
                        final isSelected = _selectedActivities.contains(
                          activity.label,
                        );
                        return FilterChip(
                          avatar: Icon(
                            activity.icon,
                            size: 18,
                            color: isSelected
                                ? colors.onSecondaryContainer
                                : colors.onSurface.withValues(alpha: 0.6),
                          ),
                          label: Text(activity.label),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: colors.secondaryContainer,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedActivities.add(activity.label);
                              } else {
                                _selectedActivities.remove(activity.label);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- Submit Button ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                      : colors.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? colors.onPrimaryContainer
                    : colors.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                      : colors.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
