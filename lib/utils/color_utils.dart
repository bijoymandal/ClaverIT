import 'package:flutter/material.dart';

class ColorUtils {
  static const List<LinearGradient> avatarGradients = [
    LinearGradient(
      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Blue
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF512F), Color(0xFFDD2476)], // Red/Pink
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF11998e), Color(0xFF38ef7d)], // Green
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF2994A), Color(0xFFF2C94C)], // Orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.grey, Colors.black],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient getAvatarGradient(String name) {
    final hash = name.hashCode;
    final index = hash.abs() % (avatarGradients.length - 1);
    return avatarGradients[index];
  }
}
