import 'package:flutter/material.dart';

/// CropLens brand palette — a green, agricultural-themed identity.
class AppColors {
  AppColors._();

  // Brand greens
  static const Color primary = Color(0xFF2E7D32); // deep leaf green
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Accent
  static const Color accent = Color(0xFFFFB300); // warm amber — sun/harvest accent
  static const Color accentSoft = Color(0xFFFFE082);

  // Status colors
  static const Color healthy = Color(0xFF43A047);
  static const Color infected = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);

  // Neutrals — light theme
  static const Color lightBackground = Color(0xFFF6FAF6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E7E1);
  static const Color lightTextPrimary = Color(0xFF1B1F1C);
  static const Color lightTextSecondary = Color(0xFF5C6B60);

  // Neutrals — dark theme
  static const Color darkBackground = Color(0xFF0E1410);
  static const Color darkSurface = Color(0xFF17201A);
  static const Color darkBorder = Color(0xFF283329);
  static const Color darkTextPrimary = Color(0xFFEAF2EB);
  static const Color darkTextSecondary = Color(0xFFA3B3A6);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF2E7D32), Color(0xFF66BB6A)];
  static const List<Color> heroGradient = [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)];
}
