import 'package:flutter/material.dart';

/// Habit icon name -> Material IconData.
IconData habitIconFromName(String? name) {
  if (name == null || name.isEmpty) return Icons.star;
  switch (name) {
    case 'fitness_center':
      return Icons.fitness_center;
    case 'menu_book':
      return Icons.menu_book;
    case 'local_drink':
      return Icons.local_drink;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'bedtime':
      return Icons.bedtime;
    case 'eco':
      return Icons.eco;
    case 'psychology':
      return Icons.psychology;
    case 'work':
      return Icons.work;
    case 'volunteer_activism':
      return Icons.volunteer_activism;
    case 'star':
      return Icons.star;
    case 'check_circle':
      return Icons.check_circle;
    case 'flag':
      return Icons.flag;
    default:
      return Icons.star;
  }
}

/// Hex color string (e.g. "22C55E" or "#22C55E") -> Color.
Color habitColorFromHex(String? hex, {Color fallback = const Color(0xFF22C55E)}) {
  if (hex == null || hex.isEmpty) return fallback;
  String s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length != 6 && s.length != 8) return fallback;
  final n = int.tryParse(s, radix: 16);
  if (n == null) return fallback;
  if (s.length == 6) return Color(0xFF000000 | n);
  return Color(n);
}
