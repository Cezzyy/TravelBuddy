import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/data/app_db.dart';
import '../../../auth/data/user_repository.dart';
import '../../data/trip_invitation_repository.dart';
import '../../domain/trip_role.dart';
import '../providers/trip_collaborators_provider.dart';
import 'collaborator_item.dart';

class CollaboratorList extends ConsumerWidget {
  const CollaboratorList({
    required this.tripId,
    required this.ownerId,
    required this.userRole,
    super.key,
  });

  final String tripId;
  final String ownerId;
  final TripRole? userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collaboratorsAsync = ref.watch(tripCollaboratorsProvider(tripId));
    final theme = Theme.of(context);
    final canManage = userRole?.canManageCollaborators ?? false;

    return collaboratorsAsync.when(
      data: (collaborators) {
        if (collaborators.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Collaborators',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${collaborators.length + 1}', // +1 for owner
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Owner
            FutureBuilder<User?>(
              future: ref.read(userRepositoryProvider).getLocalUser(ownerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final owner = snapshot.data!;
                return CollaboratorItem(
                  user: owner,
                  role: TripRole.owner,
                  isOwner: true,
                  canManage: false,
                );
              },
            ),

            // Collaborators
            ...collaborators.map((collaborator) {
              return FutureBuilder<User?>(
                future: ref
                    .read(userRepositoryProvider)
                    .getLocalUser(collaborator.userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final user = snapshot.data!;
                  final role = TripRole.fromString(collaborator.role);

                  return CollaboratorItem(
                    user: user,
                    role: role,
                    isOwner: false,
                    canManage: canManage,
                    onRemove: canManage
                        ? () => _showRemoveDialog(
                            context,
                            ref,
                            user,
                            collaborator,
                          )
                        : null,
                    onChangeRole: canManage
                        ? () => _showChangeRoleDialog(
                            context,
                            ref,
                            user,
                            collaborator,
                            role,
                          )
                        : null,
                  );
                },
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) {
        AppLogger.talker.error('Failed to load collaborators: $error');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Failed to load collaborators',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRemoveDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
    TripCollaborator collaborator,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Collaborator'),
        content: Text(
          'Are you sure you want to remove ${user.displayName ?? user.email} from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(tripInvitationRepositoryProvider);
        await repo.removeCollaborator(
          tripId: tripId,
          userId: collaborator.userId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${user.displayName ?? user.email}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        AppLogger.talker.error('Failed to remove collaborator: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove collaborator: $e'),
              backgroundColor: AppColors.error,
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

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
    TripCollaborator collaborator,
    TripRole currentRole,
  ) async {
    TripRole? selectedRole = currentRole;

    final newRole = await showDialog<TripRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TripRole.values
                .where((role) => role != TripRole.owner)
                .map((role) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedRole = role;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedRole == role
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedRole == role
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          width: selectedRole == role ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedRole == role
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedRole == role
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selectedRole == role
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedRole),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );

    if (newRole != null && newRole != currentRole && context.mounted) {
      try {
        final repo = ref.read(tripInvitationRepositoryProvider);
        await repo.updateCollaboratorRole(
          tripId: tripId,
          userId: collaborator.userId,
          newRole: newRole,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Changed ${user.displayName ?? user.email}\'s role to ${newRole.displayName}',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        AppLogger.talker.error('Failed to change role: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change role: $e'),
              backgroundColor: AppColors.error,
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
}
