import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/auth_provider.dart';

/// Auth screen with an auto-scrolling image slideshow on top
/// and a rounded-corner card at the bottom with sign-in options.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  static const _kStartPage = 1000;
  final _pageController = PageController(initialPage: _kStartPage);
  int _realIndex = 0;
  Timer? _slideshowTimer;
  int _rawPage = _kStartPage;

  late final AnimationController _entryController;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardOpacity;

  late final AnimationController _slideshowEntryController;
  late final Animation<Offset> _slideshowSlide;
  late final Animation<double> _slideshowOpacity;

  // Placeholder slideshow data — swap with real images later.
  static const _slides = [
    _SlideData(
      icon: Icons.beach_access_rounded,
      color: Color(0xFF1B6B93),
      title: 'Discover Beaches',
      subtitle: 'Find hidden coastal gems around the world',
    ),
    _SlideData(
      icon: Icons.terrain_rounded,
      color: Color(0xFF2E7D32),
      title: 'Explore Mountains',
      subtitle: 'Plan hikes and summit adventures together',
    ),
    _SlideData(
      icon: Icons.location_city_rounded,
      color: Color(0xFFE65100),
      title: 'City Adventures',
      subtitle: 'Curate urban itineraries with friends',
    ),
    _SlideData(
      icon: Icons.restaurant_rounded,
      color: Color(0xFF6A1B9A),
      title: 'Food Journeys',
      subtitle: 'Track the best eats at every destination',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeIn),
      ),
    );

    // Slideshow intro: slides down from above and fades in
    _slideshowEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideshowSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideshowEntryController,
            curve: Curves.easeOutCubic,
          ),
        );
    _slideshowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideshowEntryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideshowEntryController.forward();
    _entryController.forward();

    _startSlideshow();
  }

  void _startSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      _rawPage++;
      _pageController.animateToPage(
        _rawPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = null;
  }

  @override
  void dispose() {
    _stopSlideshow();
    _pageController.dispose();
    _entryController.dispose();
    _slideshowEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(emailAuthControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // ── Top: Slideshow (takes ~55% of screen) ──
          Positioned.fill(
            bottom: MediaQuery.sizeOf(context).height * 0.40,
            child: SlideTransition(
              position: _slideshowSlide,
              child: FadeTransition(
                opacity: _slideshowOpacity,
                child: _buildSlideshow(),
              ),
            ),
          ),

          // ── Bottom: Rounded auth card ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.48,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardOpacity,
                child: _buildAuthCard(context),
              ),
            ),
          ),

          // ── Loading overlay ──
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    margin: EdgeInsets.all(32),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Signing you in...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Slideshow
  // ─────────────────────────────────────────────
  Widget _buildSlideshow() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() {
            _rawPage = i;
            _realIndex = i % _slides.length;
          }),
          // Virtually infinite — always scrolls forward
          itemBuilder: (context, index) {
            final slide = _slides[index % _slides.length];
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [slide.color, slide.color.withValues(alpha: 0.7)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slide.icon, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Page indicator dots
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _realIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Auth card
  // ─────────────────────────────────────────────
  Widget _buildAuthCard(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section: handle + headings
                    Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Get Started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to plan your next adventure',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Middle section: buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          // ── Google button ──
                          _SignInButton(
                            onPressed: () {
                              _handleGoogleSignIn();
                            },
                            icon: Icons.g_mobiledata_rounded,
                            iconSize: 28,
                            label: 'Continue with Google',
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            borderColor: AppColors.surfaceVariant,
                          ),
                          const SizedBox(height: 14),
                          // ── Email button ──
                          _SignInButton(
                            onPressed: () {
                              _stopSlideshow();
                              context.push(RoutePaths.authEmail).then((_) {
                                if (mounted) _startSlideshow();
                              });
                            },
                            icon: Icons.email_outlined,
                            iconSize: 22,
                            label: 'Continue with Email',
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    // Bottom section: terms
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final controller = ref.read(emailAuthControllerProvider.notifier);
    try {
      await controller.signInWithGoogle();
      // Navigation is handled by GoRouter redirect on auth state change
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// ─────────────────────────────────────────────
// Supporting widgets / data
// ─────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.iconSize = 24,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double iconSize;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: foregroundColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
