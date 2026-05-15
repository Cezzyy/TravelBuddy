import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/data/providers/database_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/background_sync.dart';
import '../../auth/data/user_repository.dart';
import '../../../core/logging/app_logger.dart';
import 'providers/home_providers.dart';
import 'widgets/guide_card.dart';
import 'widgets/hero_banner.dart';
import 'widgets/landmark_card.dart';
import 'widgets/section_header.dart';
import 'widgets/trip_card.dart';
import '../../guides/presentation/guide_detail_screen.dart';
import '../../trips/presentation/trip_detail_screen.dart';
import '../../trips/presentation/trip_form_screen.dart';

/// Home screen with hero banner, guides, landmarks, and trips.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    // Trigger background sync when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBackgroundSync();
    });
  }

  Future<void> _triggerBackgroundSync() async {
    if (_hasSynced) return;

    final authRepo = ref.read(authRepositoryProvider);
    final firebaseUser = authRepo.currentUser;

    if (firebaseUser == null) return;

    try {
      _hasSynced = true;
      AppLogger.talker.info('Triggering background sync to local DB');

      final db = ref.read(appDatabaseProvider);
      final firestore = FirebaseFirestore.instance;
      final sync = BackgroundSync(db, firestore);

      await sync.syncUserToLocalDB(firebaseUser);
      AppLogger.talker.info('Background sync completed');
    } catch (e, st) {
      AppLogger.talker.error('Background sync error', e, st);
      // Don't show error to user - this is background operation
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredGuidesAsync = ref.watch(featuredGuidesProvider);
    final upcomingTripsAsync = ref.watch(homeUpcomingTripsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Banner - Full width, no padding
          SliverToBoxAdapter(
            child: HeroBanner(onCreateTrip: _navigateToCreateTrip),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Featured Guides Section
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Featured Guides',
              actionLabel: 'See all',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: featuredGuidesAsync.when(
                data: (guides) {
                  if (guides.isEmpty) {
                    return _buildEmptyState('No guides available yet');
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: guides.length,
                    itemBuilder: (context, index) {
                      final guide = guides[index];
                      return FutureBuilder(
                        future: ref
                            .read(userRepositoryProvider)
                            .getLocalUser(guide.authorId),
                        builder: (context, snapshot) {
                          final authorName =
                              snapshot.data?.displayName ?? 'Unknown';
                          return GuideCard(
                            title: guide.title,
                            destination: guide.destination,
                            authorName: authorName,
                            imageUrl: guide.coverImageUrl,
                            likeCount: guide.likeCount,
                            onTap: () => _navigateToGuideDetail(guide.id),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _buildEmptyState('Failed to load guides'),
              ),
            ),
          ),

          // Famous Landmarks Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Famous Landmarks',
              actionLabel: 'Explore',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  LandmarkCard(
                    name: 'Eiffel Tower',
                    location: 'Paris, France',
                    imageUrl: null,
                    onTap: () {
                      // Coming soon - landmarks feature
                    },
                  ),
                  LandmarkCard(
                    name: 'Great Wall',
                    location: 'Beijing, China',
                    imageUrl: null,
                    onTap: () {
                      // Coming soon - landmarks feature
                    },
                  ),
                  LandmarkCard(
                    name: 'Colosseum',
                    location: 'Rome, Italy',
                    imageUrl: null,
                    onTap: () {
                      // Coming soon - landmarks feature
                    },
                  ),
                  LandmarkCard(
                    name: 'Taj Mahal',
                    location: 'Agra, India',
                    imageUrl: null,
                    onTap: () {
                      // Coming soon - landmarks feature
                    },
                  ),
                ],
              ),
            ),
          ),

          // Upcoming Trips Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Upcoming Trips',
              actionLabel: 'View all',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: upcomingTripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState('No upcoming trips'),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final trip = trips[index];
                    final daysUntil = trip.startDate
                        .difference(DateTime.now())
                        .inDays;
                    return TripCard(
                      title: trip.title,
                      destination: trip.destination,
                      startDate: trip.startDate,
                      endDate: trip.endDate,
                      coverImageUrl: trip.coverImageUrl,
                      daysUntil: daysUntil,
                      onTap: () => _navigateToTripDetail(trip.id),
                    );
                  }, childCount: trips.length > 2 ? 2 : trips.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: _buildEmptyState('Failed to load trips'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _navigateToGuideDetail(String guideId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GuideDetailScreen(guideId: guideId)),
    );
  }

  void _navigateToTripDetail(String tripId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: tripId)));
  }

  void _navigateToCreateTrip() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TripFormScreen()));
  }
}
