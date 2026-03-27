import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

/// Artistic splash screen with floating travel icons
/// and staggered text reveal.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _floatingController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _bgShift = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _startSequence();
  }

  Future<void> _startSequence() async {
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();
    // Hold, then navigate — router crossfade handles the transition
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.goNamed(RouteNames.auth);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    AppColors.primaryDark,
                    const Color(0xFF0A2647),
                    _bgShift.value,
                  )!,
                  Color.lerp(
                    AppColors.primary,
                    const Color(0xFF144272),
                    _bgShift.value,
                  )!,
                  Color.lerp(
                    AppColors.primaryLight,
                    const Color(0xFF2C74B3),
                    _bgShift.value,
                  )!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              ..._buildFloatingIcons(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) => Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          ),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.25),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: const Text(
                          'TravelBuddy',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _subtitleOpacity,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Plan', style: _subtitleStyle),
                          _dot(),
                          Text('Explore', style: _subtitleStyle),
                          _dot(),
                          Text('Together', style: _subtitleStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _subtitleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: Colors.white.withValues(alpha: 0.9),
    letterSpacing: 1,
  );

  Widget _dot() => FadeTransition(
    opacity: _dotsOpacity,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.circle,
        size: 6,
        color: AppColors.accentLight.withValues(alpha: 0.9),
      ),
    ),
  );

  List<Widget> _buildFloatingIcons() {
    const icons = [
      Icons.luggage_rounded,
      Icons.beach_access_rounded,
      Icons.map_rounded,
      Icons.camera_alt_rounded,
      Icons.explore_rounded,
      Icons.sailing_rounded,
      Icons.terrain_rounded,
      Icons.restaurant_rounded,
    ];

    final rng = Random(42);

    return List.generate(icons.length, (i) {
      final startX = rng.nextDouble();
      final startY = rng.nextDouble();
      final driftX = (rng.nextDouble() - 0.5) * 0.06;
      final driftY = (rng.nextDouble() - 0.5) * 0.06;
      final phase = rng.nextDouble() * 2 * pi;
      final size = 20.0 + rng.nextDouble() * 12;
      final opacity = 0.06 + rng.nextDouble() * 0.1;

      return AnimatedBuilder(
        animation: _floatingController,
        builder: (context, _) {
          final t = _floatingController.value * 2 * pi + phase;
          final screenSize = MediaQuery.sizeOf(context);
          return Positioned(
            left: (startX + sin(t) * driftX) * screenSize.width,
            top: (startY + cos(t) * driftY) * screenSize.height,
            child: Icon(
              icons[i],
              size: size,
              color: Colors.white.withValues(alpha: opacity),
            ),
          );
        },
      );
    });
  }
}
