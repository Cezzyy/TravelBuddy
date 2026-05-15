import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/data/app_db.dart';
import '../../auth/data/user_repository.dart';
import '../data/trip_repository.dart';
import 'providers/trip_invitations_provider.dart';
import 'widgets/invitation_card.dart';

class TripInvitationsScreen extends ConsumerWidget {
  const TripInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(userPendingInvitationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Invitations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Invitations',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have any pending trip invitations',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];

              return FutureBuilder<Trip?>(
                future: ref
                    .read(tripRepositoryProvider)
                    .getTrip(invitation.tripId),
                builder: (context, tripSnapshot) {
                  if (!tripSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final trip = tripSnapshot.data!;

                  return FutureBuilder<User?>(
                    future: ref
                        .read(userRepositoryProvider)
                        .getLocalUser(invitation.invitedByUserId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final invitedByUser = userSnapshot.data!;

                      return InvitationCard(
                        invitation: invitation,
                        trip: trip,
                        invitedByUser: invitedByUser,
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load invitations',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
