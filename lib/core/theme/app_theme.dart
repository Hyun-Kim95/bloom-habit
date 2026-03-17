import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bloom Habit 디자인 토큰 (admin CSS oklch 팔레트와 동일한 톤)
class AppColors {
  // Light (oklch 기반 근사 hex)
  static const Color background = Color(0xFFF5F6FB);
  static const Color foreground = Color(0xFF4A4D5E);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF4A4D5E);
  static const Color primary = Color(0xFF5CB86B);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFE8EAF2);
  static const Color secondaryForeground = Color(0xFF5A5D72);
  static const Color muted = Color(0xFFF2F2F7);
  static const Color mutedForeground = Color(0xFF6B6E80);
  static const Color accent = Color(0xFFD4F0E3);
  static const Color accentForeground = Color(0xFF4A4D5E);
  static const Color destructive = Color(0xFFE54D4D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E9EF);
  static const Color input = Color(0xFFE8E9EF);
  static const Color ring = Color(0xFF5CB86B);

  // Dark
  static const Color backgroundDark = Color(0xFF2D3048);
  static const Color foregroundDark = Color(0xFFE4E4EE);
  static const Color cardDark = Color(0xFF3A3C58);
  static const Color primaryDark = Color(0xFF6DD99A);
  static const Color primaryForegroundDark = Color(0xFF2D3048);
  static const Color secondaryDark = Color(0xFF454770);
  static const Color mutedDark = Color(0xFF363855);
  static const Color borderDark = Color(0xFF5A5D72);
  static const Color inputDark = Color(0xFF5A5D72);
  static const Color ringDark = Color(0xFF6DD99A);
}

class AppTheme {
  static const double radius = 8.0; // 0.5rem
  static const double radiusSm = 4.0;
  static const double radiusLg = 12.0;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.background,
        onSurface: AppColors.foreground,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        outline: AppColors.border,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.ring, width: 2),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.mutedForeground),
        hintStyle: GoogleFonts.dmSans(color: AppColors.mutedForeground),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 2,
      ),
      textTheme: _buildTextTheme(GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme), AppColors.foreground),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
        contentTextStyle: GoogleFonts.dmSans(fontSize: 15, color: AppColors.foreground),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.backgroundDark,
        onSurface: AppColors.foregroundDark,
        primary: AppColors.primaryDark,
        onPrimary: AppColors.primaryForegroundDark,
        secondary: AppColors.secondaryDark,
        onSecondary: AppColors.foregroundDark,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        outline: AppColors.borderDark,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.foregroundDark,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foregroundDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.primaryForegroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundDark,
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.inputDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.ringDark, width: 2),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.mutedForeground),
        hintStyle: GoogleFonts.dmSans(color: AppColors.mutedForeground),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.primaryForegroundDark,
        elevation: 2,
      ),
      textTheme: _buildTextTheme(GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme), AppColors.foregroundDark),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foregroundDark),
        contentTextStyle: GoogleFonts.dmSans(fontSize: 15, color: AppColors.foregroundDark),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return base.apply(bodyColor: color, displayColor: color);
  }
}
