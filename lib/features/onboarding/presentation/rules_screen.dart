import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/errors/error_state_widget.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  bool _agreed = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to agree before continuing')),
      );
      return;
    }

    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Update Firestore directly
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(firebaseUser.uid).update({
        'hasAgreedToRules': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Router will automatically navigate to home
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

  static const _rules = [
    _RuleItem(
      Icons.handshake_rounded,
      'Respect & Communication',
      'Treat fellow travellers with courtesy. Communicate plans and changes clearly with your trip collaborators.',
    ),
    _RuleItem(
      Icons.lock_outline_rounded,
      'Privacy & Trust',
      'Only share trip details, locations, and personal information with people you trust.',
    ),
    _RuleItem(
      Icons.edit_calendar_rounded,
      'Accurate Itineraries',
      'Keep your itinerary updates timely and accurate so everyone stays on the same page.',
    ),
    _RuleItem(
      Icons.gavel_rounded,
      'Local Laws & Guidelines',
      'Respect and follow local laws, customs, and travel advisories at every destination.',
    ),
    _RuleItem(
      Icons.shield_outlined,
      'Safety First',
      'Share your plans with someone you trust and follow recommended safety practices while travelling.',
    ),
    _RuleItem(
      Icons.eco_rounded,
      'Travel Responsibly',
      'Be mindful of the environment and local communities. Leave every place better than you found it.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Community Guidelines',
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
                      'Before You Start Exploring',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review our community guidelines for safe and enjoyable travel planning.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ..._rules.map(
                      (rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RuleCard(rule: rule),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _agreed
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _agreed
                                ? AppColors.primary
                                : AppColors.surfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            width: _agreed ? 2 : 1,
                          ),
                          boxShadow: _agreed
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _agreed
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreed
                                      ? AppColors.primary
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: 2,
                                ),
                              ),
                              child: _agreed
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'I have read and agree to the community guidelines',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _agreed
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  onPressed: _agreed && !_isSubmitting ? _submit : null,
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
                          'Get Started',
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

class _RuleItem {
  const _RuleItem(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});
  final _RuleItem rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rule.icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rule.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
