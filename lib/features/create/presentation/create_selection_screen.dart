import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

/// Screen that allows users to choose between creating a Trip or Guide.
/// Shown when the plus button in the bottom navigation is tapped.
/// Features a split-screen design with left/right navigation.
class CreateSelectionScreen extends ConsumerWidget {
  const CreateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Split screen layout - vertical
            Column(
              children: [
                // Top side - Plan a Trip
                Expanded(
                  child: _CreateOptionSide(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF8C61), // Warm coral
                        Color(0xFFFF6B35), // Sunset coral
                      ],
                    ),
                    icon: Icons.luggage_rounded,
                    title: 'Plan a Trip',
                    subtitle: 'Create your perfect itinerary',
                    features: const [
                      'Day-by-day plans',
                      'Collaborate with friends',
                      'Track your budget',
                    ],
                    arrowDirection: Icons.arrow_back_rounded,
                    swipeDirection: DismissDirection.endToStart,
                    onTap: () => _handleCreateTrip(context),
                  ),
                ),
                
                // Bottom side - Write a Guide
                Expanded(
                  child: _CreateOptionSide(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5DD9C1), // Turquoise
                        Color(0xFF4FC0D0), // Tropical water
                      ],
                    ),
                    icon: Icons.menu_book_rounded,
                    title: 'Write a Guide',
                    subtitle: 'Share your experiences',
                    features: const [
                      'Tell your story',
                      'Inspire other travelers',
                      'Build community',
                    ],
                    arrowDirection: Icons.arrow_forward_rounded,
                    swipeDirection: DismissDirection.startToEnd,
                    onTap: () => _handleCreateGuide(context),
                  ),
                ),
              ],
            ),
            
            // Close button overlay
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreateTrip(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create Trip - Coming Soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleCreateGuide(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create Guide - Coming Soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _CreateOptionSide extends StatefulWidget {
  const _CreateOptionSide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.arrowDirection,
    required this.swipeDirection,
    required this.onTap,
  });

  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final IconData arrowDirection;
  final DismissDirection swipeDirection;
  final VoidCallback onTap;

  @override
  State<_CreateOptionSide> createState() => _CreateOptionSideState();
}

class _CreateOptionSideState extends State<_CreateOptionSide> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 380;
    final isShortScreen = screenHeight < 700;
    
    return Dismissible(
      key: ValueKey(widget.title),
      direction: widget.swipeDirection,
      onDismissed: (_) => widget.onTap(),
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.gradient.colors.first.withValues(alpha: 0.3),
              widget.gradient.colors.last.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated circles in background
            Positioned(
              top: 20,
              left: widget.swipeDirection == DismissDirection.endToStart ? null : 40,
              right: widget.swipeDirection == DismissDirection.endToStart ? 40 : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: widget.swipeDirection == DismissDirection.endToStart ? null : 20,
              right: widget.swipeDirection == DismissDirection.endToStart ? 20 : null,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Arrow with glow effect
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  widget.arrowDirection,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient,
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -30,
                  right: 20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                
                // Content
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 28,
                      vertical: isShortScreen ? 16 : 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(
                            isShortScreen ? 14 : (isSmallScreen ? 16 : 20),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: isShortScreen ? 36 : (isSmallScreen ? 40 : 48),
                            color: Colors.white,
                          ),
                        ),
                        
                        SizedBox(height: isShortScreen ? 14 : (isSmallScreen ? 16 : 20)),
                        
                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: isShortScreen ? 22 : (isSmallScreen ? 24 : 28),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isShortScreen ? 6 : (isSmallScreen ? 7 : 8)),
                        
                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: isShortScreen ? 13 : (isSmallScreen ? 13.5 : 14),
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isShortScreen ? 14 : (isSmallScreen ? 16 : 20)),
                        
                        // Features
                        ...widget.features.map((feature) => Padding(
                          padding: EdgeInsets.only(
                            bottom: isShortScreen ? 6 : (isSmallScreen ? 7 : 8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: isShortScreen ? 14 : (isSmallScreen ? 15 : 16),
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: isShortScreen ? 12 : (isSmallScreen ? 12.5 : 13),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                        
                        SizedBox(height: isShortScreen ? 14 : (isSmallScreen ? 16 : 20)),
                        
                        // Arrow indicator with swipe hint
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.arrowDirection,
                              size: isShortScreen ? 28 : (isSmallScreen ? 30 : 32),
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            SizedBox(height: isShortScreen ? 6 : 8),
                            Text(
                              'Swipe ${widget.swipeDirection == DismissDirection.endToStart ? 'left' : 'right'} or tap',
                              style: TextStyle(
                                fontSize: isShortScreen ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
