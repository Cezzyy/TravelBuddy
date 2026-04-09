import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/guide_card.dart';
import 'widgets/hero_banner.dart';
import 'widgets/landmark_card.dart';
import 'widgets/section_header.dart';
import 'widgets/trip_card.dart';

/// Home screen with hero banner, guides, landmarks, and trips.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Banner - Full width, no padding
          SliverToBoxAdapter(
            child: HeroBanner(onCreateTrip: () => _showComingSoon(context)),
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  GuideCard(
                    title: '5 Days in Tokyo: A Complete Guide',
                    destination: 'Tokyo, Japan',
                    authorName: 'Sarah Chen',
                    imageUrl: null,
                    likeCount: 234,
                    onTap: () => _showComingSoon(context),
                  ),
                  GuideCard(
                    title: 'Paris on a Budget',
                    destination: 'Paris, France',
                    authorName: 'Mike Johnson',
                    imageUrl: null,
                    likeCount: 189,
                    onTap: () => _showComingSoon(context),
                  ),
                  GuideCard(
                    title: 'Bali Adventure Guide',
                    destination: 'Bali, Indonesia',
                    authorName: 'Emma Wilson',
                    imageUrl: null,
                    likeCount: 312,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
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
                    onTap: () => _showComingSoon(context),
                  ),
                  LandmarkCard(
                    name: 'Great Wall',
                    location: 'Beijing, China',
                    imageUrl: null,
                    onTap: () => _showComingSoon(context),
                  ),
                  LandmarkCard(
                    name: 'Colosseum',
                    location: 'Rome, Italy',
                    imageUrl: null,
                    onTap: () => _showComingSoon(context),
                  ),
                  LandmarkCard(
                    name: 'Taj Mahal',
                    location: 'Agra, India',
                    imageUrl: null,
                    onTap: () => _showComingSoon(context),
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TripCard(
                  title: 'Summer Vacation',
                  destination: 'Bali, Indonesia',
                  startDate: DateTime.now().add(const Duration(days: 15)),
                  endDate: DateTime.now().add(const Duration(days: 22)),
                  coverImageUrl: null,
                  daysUntil: 15,
                  onTap: () => _showComingSoon(context),
                ),
                TripCard(
                  title: 'Weekend Getaway',
                  destination: 'Kyoto, Japan',
                  startDate: DateTime.now().add(const Duration(days: 30)),
                  endDate: DateTime.now().add(const Duration(days: 33)),
                  coverImageUrl: null,
                  daysUntil: 30,
                  onTap: () => _showComingSoon(context),
                ),
              ]),
            ),
          ),

          // Continue Planning Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Continue Planning'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Integrated list items (no card containers)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPlanningItem(
                  context,
                  title: 'Europe Backpacking',
                  subtitle: '12 days • 5 cities',
                  imageUrl: null,
                ),
                const SizedBox(height: 20),
                _buildPlanningItem(
                  context,
                  title: 'Southeast Asia Guide',
                  subtitle: 'Draft • 8 destinations',
                  imageUrl: null,
                ),
                const SizedBox(height: 20),
                _buildPlanningItem(
                  context,
                  title: 'New York City Trip',
                  subtitle: '5 days • 15 activities',
                  imageUrl: null,
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildPlanningItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Square image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming Soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
