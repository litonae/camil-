import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF111111);
  static const Color border = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFC1121F);
  static const Color primaryDark = Color(0xFF780000);
  static const Color accent = Color(0xFF8B8B8B);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8B8B8B);

  // Luxury gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC1121F),
      Color(0xFF780000),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF111111),
      Color(0xFF050505),
    ],
  );
}
