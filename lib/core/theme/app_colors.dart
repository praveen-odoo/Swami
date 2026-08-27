import 'package:flutter/material.dart';

/// Luxury spiritual palette:
/// deep maroon + temple gold + saffron + warm ivory.
class AppColors {
  AppColors._();

  // Core brand
  static const Color maroon = Color(0xFF4E0D0D); // deep temple maroon
  static const Color maroonDark = Color(0xFF330808);
  static const Color saffron = Color(0xFFEF7B1A); // kesariya
  static const Color gold = Color(0xFFC9A227); // antique gold
  static const Color goldLight = Color(0xFFE8C766);

  // Surfaces
  static const Color ivory = Color(0xFFFFF9EF); // warm background
  static const Color card = Color(0xFFFFFFFF);
  static const Color sandalwood = Color(0xFFF3E7CF); // soft section bg

  // Text
  static const Color textPrimary = Color(0xFF2B1607);
  static const Color textSecondary = Color(0xFF6F5B45);
  static const Color onDark = Color(0xFFFFF6E5);

  // Feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB3261E);

  static const LinearGradient maroonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [maroon, maroonDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold],
  );
}
