import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../../../core/router/route_names.dart';

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
      if (mounted) context.goNamed(RouteNames.auth);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUserProfile(userId: firebaseUser.uid, hasAgreedToRules: true);
      if (mounted) {
        context.goNamed(RouteNames.home);
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Guidelines')),
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
                      'Before You Start Exploring',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please review our community guidelines for safe and enjoyable travel planning.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._rules.map(
                      (rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RuleCard(rule: rule, colors: colors),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: _agreed
                          ? colors.primaryContainer.withValues(alpha: 0.4)
                          : colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _agreed = !_agreed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _agreed
                                  ? colors.primary
                                  : colors.outlineVariant,
                              width: _agreed ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _agreed
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: _agreed
                                    ? colors.primary
                                    : colors.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'I have read and agree to the community guidelines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _agreed
                                        ? colors.onPrimaryContainer
                                        : colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _agreed && !_isSubmitting ? _submit : null,
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
                      : const Text('Get Started'),
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
  const _RuleCard({required this.rule, required this.colors});
  final _RuleItem rule;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rule.icon, size: 22, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
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
