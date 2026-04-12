import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color - soft blue/violet gradient start
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF5046E5);

  // Secondary colors for accents
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color accent = Color(0xFFFF9F43);

  // Background colors - soft gradient backgrounds
  static const Color background = Color(0xFFF8F9FE);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF252542);

  // Text colors
  static const Color textPrimary = Color(0xFF1F1F2E);
  static const Color textSecondary = Color(0xFF8E8E9A);
  static const Color textPrimaryDark = Color(0xFFF5F5F7);
  static const Color textSecondaryDark = Color(0xFF8E8E9A);

  // Bubble colors - rounded, soft bubbles like Doubao
  static const Color sentBubble = Color(0xFF6C63FF);
  static const Color receivedBubble = Color(0xFFE8E8F0);
  static const Color receivedBubbleDark = Color(0xFF2D2D44);
  static const Color sentText = Colors.white;
  static const Color receivedText = Color(0xFF1F1F2E);

  // Avatar gradient colors for chat list
  static const List<Color> avatarGradientColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B9D),
    Color(0xFF00D9A6),
    Color(0xFFFF9F43),
    Color(0xFF54A0FF),
    Color(0xFF5F27CD),
    Color(0xFFFF6B6B),
    Color(0xFF00CEC9),
  ];

  // Input bar colors
  static const Color inputBackground = Color(0xFFF0F1F8);
  static const Color inputBackgroundDark = Color(0xFF2D2D44);
  static const Color inputBorder = Color(0xFFE0E0E8);
  static const Color inputBorderDark = Color(0xFF3D3D5C);
}
