import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color accent = Color(0xFFFFA502);

  // Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  // Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF252525);

  // Text Colors - Light Mode
  static const Color textMain = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  
  // Text Colors - Dark Mode
  static const Color textMainDark = Color(0xFFE8E8E8);
  static const Color textMutedDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFD63031);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C5CE7),
    Color(0xFFA29BFE),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFFF6B9D),
    Color(0xFFC44569),
  ];
}
