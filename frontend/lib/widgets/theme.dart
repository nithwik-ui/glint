import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlintTheme {
  // Light Theme Colors (Hyper-Minimal Luxury)
  static const Color primary = Color(0xFF8127CF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF9C48EA);
  static const Color backgroundLight = Color(0xFFFFFFFF); // White background
  static const Color onBackgroundLight = Color(0xFF000000); // Black text
  static const Color surfaceLight = Color(0xFFF5F5F5); // Light Gray cards
  static const Color onSurfaceLight = Color(0xFF000000); // Black text on card
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFA);
  static const Color surfaceContainerLight = Color(0xFFF5F5F5);
  static const Color surfaceContainerHighLight = Color(0xFFECECEC);
  static const Color outlineLight = Color(0xFF7E7385);
  static const Color outlineVariantLight = Color(0xFFCFC2D6);

  // Dark Theme Colors (Deep Luxury AMOLED)
  static const Color backgroundDark = Color(0xFF000000); // Black background
  static const Color onBackgroundDark = Color(0xFFFFFFFF); // White text
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark Gray cards
  static const Color onSurfaceDark = Color(0xFFFFFFFF); // White text on card
  static const Color surfaceContainerLowDark = Color(0xFF121212);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerHighDark = Color(0xFF2E2E2E);
  static const Color outlineDark = Color(0xFF9687A1);
  static const Color outlineVariantDark = Color(0xFF4A3C56);

  // Corner Radii Tokens
  static const double radiusSm = 8.0;
  static const double radiusDefault = 16.0;
  static const double radiusMd = 24.0;
  static const double radiusLg = 32.0;

  // Spacing Tokens
  static const double unit = 4.0;
  static const double gutter = 16.0;
  static const double marginMobile = 20.0;

  // Luminous Glow Shadow (Purple shadow instead of dark)
  static List<BoxShadow> glowShadow(bool isDark) {
    return [
      BoxShadow(
        color: primary.withOpacity(isDark ? 0.15 : 0.08),
        blurRadius: 30,
        offset: const Offset(0, 15),
      )
    ];
  }

  // Soft Glass Container decoration
  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = radiusMd,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        width: 1.0,
      ),
    );
  }

  // Core Text Styles mapping to Inter
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.8,
      color: color,
    );
  }

  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color,
    );
  }

  static TextStyle bodyBase(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15.0,
      fontWeight: FontWeight.normal,
      color: color,
    );
  }

  static TextStyle captionXs(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: color,
    );
  }

  // Material ThemeData Builders
  static ThemeData getThemeData(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final background = isDark ? backgroundDark : backgroundLight;
    final onSurface = isDark ? onSurfaceDark : onSurfaceLight;

    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: primary,
              onPrimary: onPrimary,
              surface: surfaceDark,
              onSurface: onSurfaceDark,
              background: backgroundDark,
              onBackground: onBackgroundDark,
            )
          : const ColorScheme.light(
              primary: primary,
              onPrimary: onPrimary,
              surface: surfaceLight,
              onSurface: onSurfaceLight,
              background: backgroundLight,
              onBackground: onBackgroundLight,
            ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.normal, color: onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
      ),
    );
  }
}
