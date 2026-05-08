import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../data/guide_repository.dart';
import 'providers/my_guides_provider.dart';
import 'widgets/guide_card.dart';

/// Screen showing the current user's own guides (published + drafts).
class MyGuidesScreen extends ConsumerWidget {
  const MyGuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('My Guides'),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Published'),
              Tab(text: 'Drafts'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PublishedTab(), _DraftsTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(RoutePaths.guideCreate),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Guide'),
        ),
      ),
    );
  }
}

// ─── Published Tab ────────────────────────────────────────────────────────────

class _PublishedTab extends ConsumerWidget {
  const _PublishedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(myPublishedGuidesProvider);

    return guidesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          _ErrorState(onRetry: () => ref.invalidate(myPublishedGuidesProvider)),
      data: (guides) {
        if (guides.isEmpty) {
          return _EmptyState(
            icon: Icons.publish_rounded,
            title: 'No published guides',
            subtitle: 'Publish a guide to share it with the community.',
            actionLabel: 'Write a Guide',
            onAction: () => context.push(RoutePaths.guideCreate),
          );
        }

        return _GuidesList(guides: guides);
      },
    );
  }
}

// ─── Drafts Tab ───────────────────────────────────────────────────────────────

class _DraftsTab extends ConsumerWidget {
  const _DraftsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(myDraftGuidesProvider);

    return guidesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          _ErrorState(onRetry: () => ref.invalidate(myDraftGuidesProvider)),
      data: (guides) {
        if (guides.isEmpty) {
          return _EmptyState(
            icon: Icons.edit_note_rounded,
            title: 'No drafts',
            subtitle: 'Start writing a guide and save it as a draft.',
            actionLabel: 'Start Writing',
            onAction: () => context.push(RoutePaths.guideCreate),
          );
        }

        return _GuidesList(guides: guides);
      },
    );
  }
}

// ─── Guides List ──────────────────────────────────────────────────────────────

class _GuidesList extends ConsumerWidget {
  const _GuidesList({required this.guides});

  final List<dynamic> guides;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final guide = guides[index];
        return GuideCard(
          guide: guide,
          onTap: () => context.push(
            RoutePaths.guideDetail.replaceFirst(':guideId', guide.id),
          ),
          showAuthorActions: true,
          onEdit: () => context.push(
            RoutePaths.guideEdit.replaceFirst(':guideId', guide.id),
          ),
          onTogglePublish: () => _togglePublish(context, ref, guide),
          onDelete: () => _confirmDelete(context, ref, guide),
        );
      },
    );
  }

  Future<void> _togglePublish(
    BuildContext context,
    WidgetRef ref,
    dynamic guide,
  ) async {
    final repo = ref.read(guideRepositoryProvider);

    try {
      if (guide.isPublished) {
        // Unpublish a published guide
        await repo.unpublishGuide(guide.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Guide moved to drafts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Check if this draft is linked to a published guide
        if (guide.publishedVersionId != null) {
          // This is a draft of a published guide - apply changes instead
          await repo.applyDraftToPublished(guide.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Changes applied successfully! Your published guide has been updated.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          // This is a new draft - publish it
          await repo.publishGuide(guide.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Guide published successfully! It\'s now visible to everyone.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Handle errors with user-friendly messages
      if (context.mounted) {
        final String errorMessage = guide.isPublished
            ? 'Failed to unpublish guide. Please try again.'
            : guide.publishedVersionId != null
            ? 'Failed to apply changes. Please check your connection and try again.'
            : 'Failed to publish guide. Please check your connection and try again.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _togglePublish(context, ref, guide),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    dynamic guide,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Guide'),
        content: Text(
          'Are you sure you want to delete "${guide.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(guideRepositoryProvider);
      await repo.deleteGuide(guide.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Guide deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
