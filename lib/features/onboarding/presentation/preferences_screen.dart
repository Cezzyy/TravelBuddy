import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/auth_repository.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/errors/error_state_widget.dart';

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
      // Update Firestore directly
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(firebaseUser.uid).update({
        'preferences': {
          'travelStyle': _selectedTravelStyle,
          'budgetLevel': _selectedBudgetLevel,
          'preferredActivities': jsonEncode(_selectedActivities.toList()),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Router will automatically navigate based on onboarding status
    } catch (e) {
      if (mounted) {
        AppErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Travel Preferences',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How Do You Like to Travel?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll tailor trip suggestions based on your style.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Travel Style ---
                    const _SectionHeader(
                      icon: Icons.explore_rounded,
                      label: 'Travel Style',
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // --- Budget Level ---
                    const _SectionHeader(
                      icon: Icons.payments_rounded,
                      label: 'Budget Level',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _budgetLevels.map((budget) {
                        final isSelected = _selectedBudgetLevel == budget.label;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: budget != _budgetLevels.last ? 12 : 0,
                            ),
                            child: _BudgetCard(
                              icon: budget.icon,
                              label: budget.label,
                              hint: budget.hint,
                              isSelected: isSelected,
                              onTap: () => setState(
                                () => _selectedBudgetLevel = budget.label,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // --- Activities ---
                    const _SectionHeader(
                      icon: Icons.local_activity_rounded,
                      label: 'Favourite Activities',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick all that you enjoy',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _activities.map((activity) {
                        final isSelected = _selectedActivities.contains(
                          activity.label,
                        );
                        return _ActivityChip(
                          icon: activity.icon,
                          label: activity.label,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedActivities.remove(activity.label);
                              } else {
                                _selectedActivities.add(activity.label);
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
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
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
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
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
