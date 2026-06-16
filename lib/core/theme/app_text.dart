import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type system.
///
/// Three roles, chosen to read like a developer's own tooling rather than a
/// template: Syne for expressive display, Inter for calm body copy, and
/// JetBrains Mono for code-comment style eyebrows and data.
abstract final class AppText {
  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double height = 1.02,
    double spacing = -0.5,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.syne(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      shadows: shadows,
    );
  }

  static TextStyle body({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textSecondary,
    double height = 1.6,
    double spacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textTertiary,
    double spacing = 1.5,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
  }
}

/// 8pt-ish spacing scale.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;
  static const double xxxl = 120;
}

abstract final class Corners {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

/// Shared animation timings for a consistent motion language.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration med = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 800);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
}
