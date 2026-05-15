import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/logging/app_logger.dart';
import 'providers/user_preferences_provider.dart';

/// Screen for editing travel preferences.
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

  // Travel style options
  static const travelStyles = [
    {'value': 'adventure', 'label': 'Adventure', 'icon': Icons.hiking_rounded},
    {'value': 'relaxation', 'label': 'Relaxation', 'icon': Icons.spa_rounded},
    {'value': 'cultural', 'label': 'Cultural', 'icon': Icons.museum_rounded},
    {'value': 'foodie', 'label': 'Foodie', 'icon': Icons.restaurant_rounded},
    {'value': 'nature', 'label': 'Nature', 'icon': Icons.forest_rounded},
    {'value': 'urban', 'label': 'Urban', 'icon': Icons.location_city_rounded},
  ];

  // Budget level options
  static const budgetLevels = [
    {
      'value': 'budget',
      'label': 'Budget',
      'icon': Icons.savings_rounded,
      'description': 'Cost-conscious travel',
    },
    {
      'value': 'mid-range',
      'label': 'Mid-Range',
      'icon': Icons.account_balance_wallet_rounded,
      'description': 'Balanced comfort & value',
    },
    {
      'value': 'luxury',
      'label': 'Luxury',
      'icon': Icons.diamond_rounded,
      'description': 'Premium experiences',
    },
  ];

  // Activity options
  static const activities = [
    {'value': 'hiking', 'label': 'Hiking', 'icon': Icons.hiking_rounded},
    {
      'value': 'beaches',
      'label': 'Beaches',
      'icon': Icons.beach_access_rounded,
    },
    {'value': 'museums', 'label': 'Museums', 'icon': Icons.museum_rounded},
    {'value': 'food', 'label': 'Food Tours', 'icon': Icons.restaurant_rounded},
    {
      'value': 'shopping',
      'label': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'value': 'nightlife',
      'label': 'Nightlife',
      'icon': Icons.nightlife_rounded,
    },
    {
      'value': 'photography',
      'label': 'Photography',
      'icon': Icons.camera_alt_rounded,
    },
    {'value': 'wildlife', 'label': 'Wildlife', 'icon': Icons.pets_rounded},
    {'value': 'sports', 'label': 'Sports', 'icon': Icons.sports_soccer_rounded},
    {
      'value': 'wellness',
      'label': 'Wellness',
      'icon': Icons.self_improvement_rounded,
    },
    {'value': 'history', 'label': 'History', 'icon': Icons.history_edu_rounded},
    {
      'value': 'festivals',
      'label': 'Festivals',
      'icon': Icons.celebration_rounded,
    },
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
          _isInitialized = true;
        });
      }
    });
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Travel Style Section
          Text(
            'Travel Style',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What kind of traveler are you?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: travelStyles.map((style) {
              final isSelected = _selectedTravelStyle == style['value'];
              return _StyleChip(
                label: style['label'] as String,
                icon: style['icon'] as IconData,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedTravelStyle = style['value'] as String;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Budget Level Section
          Text(
            'Budget Level',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What\'s your typical travel budget?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...budgetLevels.map((budget) {
            final isSelected = _selectedBudgetLevel == budget['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BudgetCard(
                label: budget['label'] as String,
                description: budget['description'] as String,
                icon: budget['icon'] as IconData,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedBudgetLevel = budget['value'] as String;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 32),

          // Preferred Activities Section
          Text(
            'Preferred Activities',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that interest you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activities.map((activity) {
              final isSelected = _selectedActivities.contains(
                activity['value'],
              );
              return _ActivityChip(
                label: activity['label'] as String,
                icon: activity['icon'] as IconData,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedActivities.remove(activity['value']);
                    } else {
                      _selectedActivities.add(activity['value'] as String);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Save Button
          FilledButton(
            onPressed: _isLoading ? null : _handleSave,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 16),

          // Cancel Button
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      final updatePreferences = ref.read(updateUserPreferencesProvider);

      // Encode activities as JSON
      final activitiesJson = _selectedActivities.isNotEmpty
          ? jsonEncode(_selectedActivities.toList())
          : null;

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

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
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
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.accent : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
