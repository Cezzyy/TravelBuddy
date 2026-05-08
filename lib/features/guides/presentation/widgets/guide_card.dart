import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/app_db.dart';

/// Reusable card widget for displaying a guide in a list or grid.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.guide,
    required this.onTap,
    this.showAuthorActions = false,
    this.onEdit,
    this.onDelete,
    this.onTogglePublish,
  });

  final Guide guide;
  final VoidCallback onTap;
  final bool showAuthorActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            _CoverImage(
              guide: guide,
              showAuthorActions: showAuthorActions,
              onEdit: onEdit,
              onDelete: onDelete,
              onTogglePublish: onTogglePublish,
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination chip
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          guide.destination,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    guide.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    guide.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Tags
                  if (guide.tags != null && guide.tags!.isNotEmpty)
                    _TagsRow(tagsJson: guide.tags!),

                  const SizedBox(height: 10),

                  // Stats row
                  _StatsRow(guide: guide),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.guide,
    required this.showAuthorActions,
    this.onEdit,
    this.onDelete,
    this.onTogglePublish,
  });

  final Guide guide;
  final bool showAuthorActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublish;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image or placeholder
        AspectRatio(
          aspectRatio: 16 / 9,
          child: guide.coverImageUrl != null
              ? Image.network(
                  guide.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _PlaceholderImage(),
                )
              : _PlaceholderImage(),
        ),

        // Draft badge
        if (!guide.isPublished)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DRAFT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

        // Author action menu
        if (showAuthorActions)
          Positioned(
            top: 6,
            right: 6,
            child: _AuthorMenu(
              guide: guide,
              onEdit: onEdit,
              onDelete: onDelete,
              onTogglePublish: onTogglePublish,
            ),
          ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 40,
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _AuthorMenu extends StatelessWidget {
  const _AuthorMenu({
    required this.guide,
    this.onEdit,
    this.onDelete,
    this.onTogglePublish,
  });

  final Guide guide;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePublish;

  @override
  Widget build(BuildContext context) {
    // Determine the action label based on guide state
    final bool isDraftOfPublished = guide.publishedVersionId != null;
    final String publishLabel = guide.isPublished
        ? 'Unpublish'
        : isDraftOfPublished
            ? 'Apply Changes'
            : 'Publish';
    final IconData publishIcon = guide.isPublished
        ? Icons.unpublished_rounded
        : isDraftOfPublished
            ? Icons.check_circle_rounded
            : Icons.publish_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call();
            case 'toggle_publish':
              onTogglePublish?.call();
            case 'delete':
              onDelete?.call();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 16),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle_publish',
            child: Row(
              children: [
                Icon(publishIcon, size: 16),
                const SizedBox(width: 8),
                Text(publishLabel),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tagsJson});

  final String tagsJson;

  List<String> get _tags {
    try {
      if (!tagsJson.startsWith('[')) return [];
      return tagsJson
          .substring(1, tagsJson.length - 1)
          .split(',')
          .map((t) => t.trim().replaceAll('"', ''))
          .where((t) => t.isNotEmpty)
          .take(3)
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
      spacing: 6,
      runSpacing: 4,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.favorite_rounded,
          value: guide.likeCount,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _StatItem(
          icon: Icons.visibility_rounded,
          value: guide.viewCount,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        Text(
          _formatCount(value),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
