import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../core/errors/error_state_widget.dart';
import 'providers/trip_list_provider.dart';
import 'widgets/trip_card.dart';

/// Trips screen — lists the user's planned and past trips.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                Text(
                  'My Trips',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: const [_UpcomingTripsTab(), _PastTripsTab()],
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming Trips Tab ───────────────────────────────────────────────────────

class _UpcomingTripsTab extends ConsumerWidget {
  const _UpcomingTripsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(upcomingTripsProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget.fromException(
        e,
        onRetry: () => ref.invalidate(upcomingTripsProvider),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyState(
            icon: Icons.luggage_rounded,
            title: 'No upcoming trips',
            message: 'Tap the + button to plan your next adventure!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final trip = trips[index];
            return TripCard(
              trip: trip,
              onTap: () => context.push(
                RoutePaths.tripDetail.replaceFirst(':tripId', trip.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Past Trips Tab ───────────────────────────────────────────────────────────

class _PastTripsTab extends ConsumerWidget {
  const _PastTripsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(pastTripsProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget.fromException(
        e,
        onRetry: () => ref.invalidate(pastTripsProvider),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyState(
            icon: Icons.history_rounded,
            title: 'No past trips',
            message: 'Your completed trips will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final trip = trips[index];
            return TripCard(
              trip: trip,
              onTap: () => context.push(
                RoutePaths.tripDetail.replaceFirst(':tripId', trip.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
              size: 64,
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
              message,
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
