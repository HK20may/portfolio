import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// A rounded device bezel that wraps any child as the "screen".
/// Ratio ~2.05:1 (height:width). Shows a notch and a home indicator bar.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.width = 220});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 2.05;
    final bezelR = width * 0.115;
    final notchW = width * 0.30;
    final notchH = width * 0.055;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(bezelR),
        border: Border.all(color: AppColors.borderStrong, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(0.22),
            blurRadius: 48,
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(bezelR - 2),
        child: Stack(
          children: [
            // Screen content
            Positioned.fill(child: child),
            // Status bar scrim so notch blends
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: notchH * 2.2,
                color: const Color(0xFF0D0D1A),
              ),
            ),
            // Notch cutout
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: notchW,
                  height: notchH * 1.6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(notchW * 0.18),
                      bottomRight: Radius.circular(notchW * 0.18),
                    ),
                  ),
                ),
              ),
            ),
            // Status bar time
            Positioned(
              top: 4,
              left: width * 0.08,
              child: Text(
                '9:41',
                style: AppText.mono(
                  size: 9,
                  color: AppColors.textPrimary,
                  spacing: 0,
                ),
              ),
            ),
            // Home indicator bar
            Positioned(
              bottom: width * 0.04,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: width * 0.28,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
