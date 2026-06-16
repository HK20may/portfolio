import 'package:flutter/material.dart';

/// Centralised colour tokens for the aurora theme.
///
/// The shader in `shaders/aurora.frag` mirrors [violet], [cyan] and [pink],
/// so keep them in sync if you re-palette.
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFF07070E);
  static const Color surface = Color(0xFF0E0E18);
  static const Color surfaceHigh = Color(0xFF15151F);

  // Accents (the aurora trio)
  static const Color violet = Color(0xFF7C5CFF);
  static const Color cyan = Color(0xFF2DD4FF);
  static const Color pink = Color(0xFFFF5C8A);

  // Vivid variants — more saturated/luminous for Vivid palette mode
  static const Color violetVivid = Color(0xFF9B7BFF);
  static const Color cyanVivid   = Color(0xFF4DE3FF);
  static const Color pinkVivid   = Color(0xFFFF6FA0);

  // Secondary project accents
  static const Color mint = Color(0xFF49E6A6);
  static const Color amber = Color(0xFFFFB35C);

  // Text — brighter for legibility over the aurora
  static const Color textPrimary = Color(0xFFF6F6FB);
  static const Color textSecondary = Color(0xFFC7C7DA);
  static const Color textTertiary = Color(0xFF9494A8);

  // Hairlines / glass edges — slightly crisper on darker panels
  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  // Glass fills — now DARK translucent so light text reads clearly
  static const Color glass = Color(0x590B0B16); // ~35% dark, for pills/chips
  static const Color glassHigh = Color(0x730C0C18); // ~45% dark, for ghost buttons/menu

  // Primary card surface — deep translucent bed for strong contrast
  static const Color panel = Color(0xA60C0C18); // ~65% dark, used by GlassContainer

  /// Signature gradient used on the hero highlight, buttons and accents.
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, pink, cyan],
    stops: [0.0, 0.5, 1.0],
  );

  /// Returns the aurora gradient in calm or vivid variant.
  static LinearGradient auroraGradientFor(bool vivid) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: vivid
            ? const [violetVivid, pinkVivid, cyanVivid]
            : const [violet, pink, cyan],
        stops: const [0.0, 0.5, 1.0],
      );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [violet, cyan],
  );
}
