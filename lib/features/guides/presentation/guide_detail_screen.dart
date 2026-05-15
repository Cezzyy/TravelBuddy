import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/data/app_db.dart';
import '../../auth/presentation/providers/current_user_provider.dart';
import '../../auth/data/user_repository.dart';
import '../data/guide_repository.dart';
import 'providers/guide_detail_provider.dart';

/// Full guide detail screen with content, itinerary, likes and comments.
class GuideDetailScreen extends ConsumerStatefulWidget {
  const GuideDetailScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Track view after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guideDetailActionsProvider.notifier).trackView(widget.guideId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(guideDetailProvider(widget.guideId));

    return guideAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load guide: $e')),
      ),
      data: (guide) {
        if (guide == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Guide not found')),
          );
        }
        return _GuideDetailView(
          guide: guide,
          tabController: _tabController,
          commentController: _commentController,
        );
      },
    );
  }
}

class _GuideDetailView extends ConsumerWidget {
  const _GuideDetailView({
    required this.guide,
    required this.tabController,
    required this.commentController,
  });

  final Guide guide;
  final TabController tabController;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    final isAuthor = currentUser?.id == guide.authorId;
    final isLikedAsync = ref.watch(isGuideLikedProvider(guide.id));
    final isLiked = isLikedAsync.value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [if (isAuthor) _EditButton(guide: guide)],
            flexibleSpace: FlexibleSpaceBar(
              background: _CoverImageHeader(imageUrl: guide.coverImageUrl),
            ),
          ),

          // Guide metadata
          SliverToBoxAdapter(
            child: _GuideMetadata(guide: guide, isLiked: isLiked),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Guide'),
                  Tab(text: 'Itinerary'),
                  Tab(text: 'Comments'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabController,
          children: [
            // Guide content tab
            _GuideContentTab(guide: guide),

            // Itinerary tab
            _ItineraryTab(guideId: guide.id),

            // Comments tab
            _CommentsTab(guideId: guide.id),
          ],
        ),
      ),

      // Like + comment FAB area
      bottomNavigationBar: _BottomBar(
        guide: guide,
        isLiked: isLiked,
        commentController: commentController,
      ),
    );
  }
}

// ─── Cover Image Header ───────────────────────────────────────────────────────

class _CoverImageHeader extends StatelessWidget {
  const _CoverImageHeader({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          )
        else
          _placeholder(),
        // Gradient overlay for readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primaryLight.withValues(alpha: 0.2),
    child: Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 64,
        color: AppColors.primaryLight.withValues(alpha: 0.4),
      ),
    ),
  );
}

// ─── Guide Metadata ───────────────────────────────────────────────────────────

class _GuideMetadata extends ConsumerWidget {
  const _GuideMetadata({required this.guide, required this.isLiked});

  final Guide guide;
  final bool isLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(guideCommentsProvider(guide.id));
    final commentCount = commentsAsync.value?.length ?? 0;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                guide.destination,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            guide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            guide.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Tags
          if (guide.tags != null && guide.tags!.isNotEmpty)
            _TagsWrap(tagsJson: guide.tags!),

          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 14,
                color: isLiked ? Colors.redAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${guide.likeCount} likes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.visibility_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${guide.viewCount} views',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.comment_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '$commentCount comments',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (guide.publishedAt != null) ...[
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(guide.publishedAt!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tagsJson});

  final String tagsJson;

  List<String> get _tags {
    try {
      if (!tagsJson.startsWith('[')) return [];
      return tagsJson
          .substring(1, tagsJson.length - 1)
          .split(',')
          .map((t) => t.trim().replaceAll('"', ''))
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Chip(
              label: Text('#$tag'),
              labelStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }
}

// ─── Guide Content Tab ────────────────────────────────────────────────────────

class _GuideContentTab extends StatelessWidget {
  const _GuideContentTab({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (guide.content.isEmpty) {
      return Center(
        child: Text(
          'No content yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Text(
        guide.content,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          height: 1.7,
        ),
      ),
    );
  }
}

// ─── Itinerary Tab ────────────────────────────────────────────────────────────

class _ItineraryTab extends ConsumerWidget {
  const _ItineraryTab({required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(guideItineraryProvider(guideId));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load itinerary: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No itinerary added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Group items by day
        final byDay = <int, List<GuideItineraryItem>>{};
        for (final item in items) {
          byDay.putIfAbsent(item.dayNumber, () => []).add(item);
        }
        final days = byDay.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final dayItems = byDay[day]!;
            return _DaySection(day: day, items: dayItems);
          },
        );
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.items});

  final int day;
  final List<GuideItineraryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Day $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items
        ...items.map((item) => _ItineraryItemTile(item: item)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ItineraryItemTile extends StatelessWidget {
  const _ItineraryItemTile({required this.item});

  final GuideItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _categoryColor(item.category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _categoryIcon(item.category),
              size: 18,
              color: _categoryColor(item.category),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.locationName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.locationName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.estimatedCost != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '~${item.costCurrency ?? 'USD'} ${item.estimatedCost!.toStringAsFixed(0)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'transport' => Icons.directions_rounded,
      'food' => Icons.restaurant_rounded,
      'activity' => Icons.local_activity_rounded,
      'accommodation' => Icons.hotel_rounded,
      _ => Icons.place_rounded,
    };
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'transport' => Colors.blueAccent,
      'food' => Colors.orangeAccent,
      'activity' => AppColors.accent,
      'accommodation' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
  }
}

// ─── Comments Tab ─────────────────────────────────────────────────────────────

class _CommentsTab extends ConsumerWidget {
  const _CommentsTab({required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(guideCommentsProvider(guideId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;

    return commentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load comments: $e')),
      data: (comments) {
        if (comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No comments yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to comment!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final isOwnComment = currentUser?.id == comment.userId;
            return _CommentTile(comment: comment, isOwnComment: isOwnComment);
          },
        );
      },
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment, required this.isOwnComment});

  final GuideComment comment;
  final bool isOwnComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: ref.read(userRepositoryProvider).getLocalUser(comment.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user?.displayName ?? 'Unknown User';
        final userPhotoUrl = user?.photoUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwnComment
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.surfaceVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info and actions
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: userPhotoUrl != null
                        ? NetworkImage(userPhotoUrl)
                        : null,
                    child: userPhotoUrl == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isOwnComment) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'You',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(comment.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button for own comments
                  if (isOwnComment)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteDialog(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Comment content
              Text(
                comment.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[timestamp.month - 1]} ${timestamp.day}';
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(guideDetailActionsProvider.notifier)
          .deleteComment(comment.id);
    }
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.guide,
    required this.isLiked,
    required this.commentController,
  });

  final Guide guide;
  final bool isLiked;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(guideDetailActionsProvider);
    final isLoading = actionsState.isLoading;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Like button
            _LikeButton(
              guideId: guide.id,
              isLiked: isLiked,
              likeCount: guide.likeCount,
              isLoading: isLoading,
            ),
            const SizedBox(width: 12),

            // Comment input
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    color: AppColors.primary,
                    onPressed: isLoading
                        ? null
                        : () => _submitComment(context, ref),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(context, ref),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment(BuildContext context, WidgetRef ref) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    commentController.clear();
    FocusScope.of(context).unfocus();

    await ref
        .read(guideDetailActionsProvider.notifier)
        .addComment(guide.id, text);
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({
    required this.guideId,
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
  });

  final String guideId;
  final bool isLiked;
  final int likeCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () => ref
                .read(guideDetailActionsProvider.notifier)
                .toggleLike(guideId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLiked
              ? Colors.redAccent.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isLiked ? Colors.redAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              likeCount.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLiked ? Colors.redAccent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Bar Delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─── Edit Button ──────────────────────────────────────────────────────────────

class _EditButton extends ConsumerWidget {
  const _EditButton({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.edit_rounded),
      tooltip: 'Edit guide',
      onPressed: () => _handleEdit(context, ref),
    );
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref) async {
    // If this is a published guide, we need to get or create the draft version
    if (guide.isPublished) {
      final repo = ref.read(guideRepositoryProvider);

      // Check if draft already exists
      String draftId;
      if (guide.draftVersionId != null) {
        draftId = guide.draftVersionId!;
      } else {
        // Create draft version
        draftId = await repo.createDraftVersion(guide.id);
      }

      // Navigate to edit the draft
      if (context.mounted) {
        context.push(RoutePaths.guideEdit.replaceFirst(':guideId', draftId));
      }
    } else {
      // For unpublished guides, edit directly
      context.push(RoutePaths.guideEdit.replaceFirst(':guideId', guide.id));
    }
  }
}
