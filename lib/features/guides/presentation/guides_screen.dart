import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/errors/error_state_widget.dart';
import '../../../shared/data/app_db.dart';
import '../data/guide_repository.dart';
import 'providers/guide_list_provider.dart';
import 'widgets/guide_card.dart';

/// Guides discovery screen — browse and search published travel guides.
class GuidesScreen extends ConsumerStatefulWidget {
  const GuidesScreen({super.key});

  @override
  ConsumerState<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends ConsumerState<GuidesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Travel Guides',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // My Guides button
                    TextButton.icon(
                      onPressed: () => context.push(RoutePaths.myGuides),
                      icon: const Icon(Icons.person_rounded, size: 16),
                      label: const Text('My Guides'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search bar
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search destinations, guides...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clearSearch,
                          ),
                        ]
                      : null,
                  onChanged: (value) {
                    _onSearchChanged(value);
                  },
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    AppColors.surfaceVariant,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Content — search results or default browse view
        if (_searchQuery.isNotEmpty)
          _SearchResultsSliver(query: _searchQuery)
        else
          const _BrowseSliver(),
      ],
    );
  }
}

// ─── Browse View ──────────────────────────────────────────────────────────────

class _BrowseSliver extends ConsumerWidget {
  const _BrowseSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(publishedGuidesProvider);

    return guidesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: ErrorStateWidget.fromException(
          e,
          onRetry: () => ref.invalidate(publishedGuidesProvider),
        ),
      ),
      data: (guides) {
        if (guides.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList.separated(
            itemCount: guides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final guide = guides[index];
              return GuideCard(
                guide: guide,
                onTap: () => context.push(
                  RoutePaths.guideDetail.replaceFirst(':guideId', guide.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResultsSliver extends ConsumerWidget {
  const _SearchResultsSliver({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(guideRepositoryProvider);

    return FutureBuilder<List<Guide>>(
      future: repo.searchGuides(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: ErrorStateWidget.fromException(
              snapshot.error!,
              onRetry: () => ref.invalidate(guideRepositoryProvider),
            ),
          );
        }

        final guides = snapshot.data ?? [];

        if (guides.isEmpty) {
          return SliverFillRemaining(child: _EmptySearchState(query: query));
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList.separated(
            itemCount: guides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final guide = guides[index];
              return GuideCard(
                guide: guide,
                onTap: () => context.push(
                  RoutePaths.guideDetail.replaceFirst(':guideId', guide.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.menu_book_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No guides yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to share your travel experience.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

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
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different destination or keyword.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
