import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/app_db.dart';
import '../../domain/trip_role.dart';

class CollaboratorItem extends ConsumerWidget {
  const CollaboratorItem({
    required this.user,
    required this.role,
    required this.isOwner,
    required this.canManage,
    this.onRemove,
    this.onChangeRole,
    super.key,
  });

  final User user;
  final TripRole role;
  final bool isOwner;
  final bool canManage;
  final VoidCallback? onRemove;
  final VoidCallback? onChangeRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: user.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(role),
              ),
            ),
          ),

          // Actions menu (only for non-owners if user can manage)
          if (canManage && !isOwner) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                if (onChangeRole != null)
                  PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text('Change Role'),
                      ],
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_outlined,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Remove',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'change_role' && onChangeRole != null) {
                  onChangeRole!();
                } else if (value == 'remove' && onRemove != null) {
                  onRemove!();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(TripRole role) {
    switch (role) {
      case TripRole.owner:
        return AppColors.primary;
      case TripRole.editor:
        return AppColors.accent;
      case TripRole.viewer:
        return AppColors.textSecondary;
    }
  }
}
