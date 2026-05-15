import 'package:flutter/material.dart';

/// TravelBuddy brand palette.
abstract class AppColors {
  // ── Primary ──
  static const primary = Color(0xFF1B6B93); // Deep ocean blue
  static const primaryLight = Color(0xFF4FC0D0); // Tropical water
  static const primaryDark = Color(0xFF0F4C75); // Night sea

  // ── Accent ──
  static const accent = Color(0xFFFF6B35); // Sunset coral
  static const accentLight = Color(0xFFFFAB76); // Warm peach

  // ── Neutrals ──
  static const background = Color(0xFFF8F6F2); // Sandy white
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFEDE8E1); // Warm grey
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textOnPrimary = Colors.white;

  // ── Semantic ──
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF9A825);

  // ── Gradients ──
  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, primaryLight],
  );
}
