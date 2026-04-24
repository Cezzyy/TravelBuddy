import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Main shell screen with bottom navigation.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      color: AppColors.primary,
    ),
    _TabItem(
      icon: Icons.luggage_outlined,
      activeIcon: Icons.luggage_rounded,
      label: 'Trips',
      color: AppColors.accent,
    ),
    _TabItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Guides',
      color: AppColors.primaryLight,
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      color: AppColors.primary,
    ),
  ];

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showAddOptions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add Trip or Guide - Coming Soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.mode_of_travel_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              'TravelBuddy',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: 28,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications - Coming Soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            tooltip: 'Notifications',
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home
                _NavItem(
                  tab: _tabs[0],
                  isSelected: currentIndex == 0,
                  onTap: () => _onTabSelected(0),
                ),
                // Trips
                _NavItem(
                  tab: _tabs[1],
                  isSelected: currentIndex == 1,
                  onTap: () => _onTabSelected(1),
                ),
                // Plus Button (Center)
                _PlusButton(onTap: () => _showAddOptions(context)),
                // Guides
                _NavItem(
                  tab: _tabs[2],
                  isSelected: currentIndex == 2,
                  onTap: () => _onTabSelected(2),
                ),
                // Profile
                _NavItem(
                  tab: _tabs[3],
                  isSelected: currentIndex == 3,
                  onTap: () => _onTabSelected(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _TabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? tab.activeIcon : tab.icon,
          color: isSelected
              ? tab.color
              : AppColors.textSecondary.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
}
