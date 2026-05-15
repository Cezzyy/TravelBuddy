import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/logging/app_logger.dart';
import 'providers/user_preferences_provider.dart';

/// Screen for managing travel preferences from profile.
/// Different from onboarding - shows current selections and requires at least one per category.
class TravelPreferencesScreen extends ConsumerStatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  ConsumerState<TravelPreferencesScreen> createState() =>
      _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState
    extends ConsumerState<TravelPreferencesScreen> {
  String? _selectedTravelStyle;
  String? _selectedBudgetLevel;
  final Set<String> _selectedActivities = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Track initial values to show what's being changed
  String? _initialTravelStyle;
  String? _initialBudgetLevel;
  Set<String> _initialActivities = {};

  // Travel style options - matching onboarding
  static const travelStyles = [
    {'value': 'Adventure', 'icon': Icons.terrain_rounded},
    {'value': 'Relaxation', 'icon': Icons.spa_rounded},
    {'value': 'Cultural', 'icon': Icons.account_balance_rounded},
    {'value': 'Foodie', 'icon': Icons.restaurant_rounded},
    {'value': 'Backpacking', 'icon': Icons.hiking_rounded},
    {'value': 'Luxury', 'icon': Icons.diamond_rounded},
  ];

  // Budget level options
  static const budgetLevels = [
    {'value': 'Budget', 'icon': Icons.savings_rounded},
    {'value': 'Mid-range', 'icon': Icons.account_balance_wallet_rounded},
    {'value': 'Luxury', 'icon': Icons.workspace_premium_rounded},
  ];

  // Activity options
  static const activities = [
    {'value': 'Hiking', 'icon': Icons.terrain_rounded},
    {'value': 'Beach', 'icon': Icons.beach_access_rounded},
    {'value': 'Museums', 'icon': Icons.museum_rounded},
    {'value': 'Nightlife', 'icon': Icons.nightlife_rounded},
    {'value': 'Road Trips', 'icon': Icons.directions_car_rounded},
    {'value': 'Local Food', 'icon': Icons.ramen_dining_rounded},
    {'value': 'Photography', 'icon': Icons.camera_alt_rounded},
    {'value': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'value': 'Water Sports', 'icon': Icons.surfing_rounded},
    {'value': 'Wildlife', 'icon': Icons.pets_rounded},
    {'value': 'Festivals', 'icon': Icons.celebration_rounded},
    {'value': 'Wellness', 'icon': Icons.self_improvement_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Load current preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  void _loadPreferences() {
    final prefsAsync = ref.read(userPreferencesProvider);
    prefsAsync.whenData((prefs) {
      if (prefs != null && !_isInitialized) {
        setState(() {
          _selectedTravelStyle = prefs.travelStyle;
          _selectedBudgetLevel = prefs.budgetLevel;
          if (prefs.preferredActivities != null) {
            try {
              final activities = jsonDecode(prefs.preferredActivities!) as List;
              _selectedActivities.addAll(activities.cast<String>());
            } catch (e) {
              AppLogger.talker.error('Failed to parse activities: $e');
            }
          }

          // Store initial values
          _initialTravelStyle = _selectedTravelStyle;
          _initialBudgetLevel = _selectedBudgetLevel;
          _initialActivities = Set.from(_selectedActivities);

          _isInitialized = true;
        });
      }
    });
  }

  bool _hasChanges() {
    return _selectedTravelStyle != _initialTravelStyle ||
        _selectedBudgetLevel != _initialBudgetLevel ||
        !_selectedActivities.containsAll(_initialActivities) ||
        !_initialActivities.containsAll(_selectedActivities);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Travel Preferences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges())
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Modified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You must have at least one selection in each category',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Travel Style Section
                _SectionHeader(
                  icon: Icons.explore_rounded,
                  label: 'Travel Style',
                  count: _selectedTravelStyle != null ? 1 : 0,
                  required: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: travelStyles.map((style) {
                    final value = style['value'] as String;
                    final isSelected = _selectedTravelStyle == value;
                    final wasInitial = _initialTravelStyle == value;
                    return _SelectableChip(
                      label: value,
                      icon: style['icon'] as IconData,
                      isSelected: isSelected,
                      wasInitial: wasInitial,
                      onTap: () {
                        setState(() {
                          _selectedTravelStyle = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Budget Level Section
                _SectionHeader(
                  icon: Icons.payments_rounded,
                  label: 'Budget Level',
                  count: _selectedBudgetLevel != null ? 1 : 0,
                  required: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: budgetLevels.map((budget) {
                    final value = budget['value'] as String;
                    final isSelected = _selectedBudgetLevel == value;
                    final wasInitial = _initialBudgetLevel == value;
                    return _SelectableChip(
                      label: value,
                      icon: budget['icon'] as IconData,
                      isSelected: isSelected,
                      wasInitial: wasInitial,
                      onTap: () {
                        setState(() {
                          _selectedBudgetLevel = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Preferred Activities Section
                _SectionHeader(
                  icon: Icons.local_activity_rounded,
                  label: 'Preferred Activities',
                  count: _selectedActivities.length,
                  required: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all that interest you',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: activities.map((activity) {
                    final value = activity['value'] as String;
                    final isSelected = _selectedActivities.contains(value);
                    final wasInitial = _initialActivities.contains(value);
                    return _SelectableChip(
                      label: value,
                      icon: activity['icon'] as IconData,
                      isSelected: isSelected,
                      wasInitial: wasInitial,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            // Don't allow removing if it's the last one
                            if (_selectedActivities.length > 1) {
                              _selectedActivities.remove(value);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'You must have at least one activity selected',
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } else {
                            _selectedActivities.add(value);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading || !_canSave() ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    return _selectedTravelStyle != null &&
        _selectedBudgetLevel != null &&
        _selectedActivities.isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (!_canSave()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required selections'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatePreferences = ref.read(updateUserPreferencesProvider);

      // Encode activities as JSON
      final activitiesJson = jsonEncode(_selectedActivities.toList());

      await updatePreferences(
        travelStyle: _selectedTravelStyle,
        budgetLevel: _selectedBudgetLevel,
        preferredActivities: activitiesJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Preferences saved successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.talker.error('Failed to save preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.required,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: count > 0
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count selected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: count > 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.wasInitial,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool wasInitial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Determine the state
    final isNew = isSelected && !wasInitial;
    final isRemoved = !isSelected && wasInitial;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : isRemoved
              ? AppColors.error.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isRemoved
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.primary
                  : isRemoved
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : isRemoved
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textPrimary,
                decoration: isRemoved ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isNew) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
