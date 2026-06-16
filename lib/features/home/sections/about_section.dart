import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/section_header.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    final isDesktop = context.isDesktop;

    final bio = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in profile.about) ...[
          Text(
            para,
            style: AppText.body(
              size: context.responsive<double>(mobile: 16, desktop: 18),
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: Insets.lg),
        ],
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.xl,
          runSpacing: Insets.lg,
          children: [
            for (final s in profile.stats)
              StatBlock(value: s.value, label: s.label),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pageGutter,
        vertical: context.responsive(mobile: Insets.xxl, desktop: Insets.xxxl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RevealOnScroll(
              child: SectionHeader(
                eyebrow: 'about',
                title: 'Polish you can feel,\narchitecture you can trust.',
                accent: AppColors.violet,
              ),
            ),
            const SizedBox(height: Insets.xxl),
            if (isDesktop)
              RevealOnScroll(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 360, child: _ProfileCard()),
                    const SizedBox(width: Insets.xxl),
                    Expanded(child: bio),
                  ],
                ),
              )
            else
              RevealOnScroll(
                delay: const Duration(milliseconds: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileCard(),
                    const SizedBox(height: Insets.xl),
                    bio,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    return GlassContainer(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drop a square PNG at assets/images/avatar.png and declare it under
          // flutter: assets: in pubspec.yaml to display the real photo here
          // and use it as the app icon (run: dart run flutter_launcher_icons).
          ClipRRect(
            borderRadius: BorderRadius.circular(Corners.pill),
            child: Image.asset(
              'images/avatar.png',
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DrawnAvatar(),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Text(
            profile.name,
            style: AppText.display(size: 26, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            profile.roles.first,
            style: AppText.body(size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: Insets.lg),
          _InfoRow(icon: Icons.place_outlined, text: profile.location),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.mail_outline_rounded, text: profile.email),
          const SizedBox(height: 10),
          const _InfoRow(
              icon: Icons.translate_rounded, text: 'Hindi · English'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: AppColors.cyan),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: AppText.body(size: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Drawn avatar fallback ─────────────────────────────────────────────────────

/// Shown when assets/images/avatar.png is not yet present.
/// A friendly stylised cartoon face drawn in Flutter.
class _DrawnAvatar extends StatelessWidget {
  const _DrawnAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 112,
      height: 112,
      child: RepaintBoundary(
        child: CustomPaint(painter: _AvatarPainter()),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Aurora gradient background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r * 0.44)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5CFF), Color(0xFFFF5C8A), Color(0xFF2DD4FF)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Face
    canvas.drawCircle(
      center + Offset(0, r * 0.10),
      r * 0.58,
      Paint()..color = const Color(0xFFEEB896),
    );

    // Hair cap (semicircle, slightly larger than face)
    canvas.drawArc(
      Rect.fromCenter(
          center: center + Offset(0, r * 0.06),
          width: r * 1.24,
          height: r * 1.24),
      pi,
      pi,
      true,
      Paint()..color = const Color(0xFF2A1A0A),
    );
    // Side sideburns
    canvas.drawOval(
      Rect.fromCenter(
          center: center + Offset(-r * 0.55, r * 0.14),
          width: r * 0.20,
          height: r * 0.32),
      Paint()..color = const Color(0xFF2A1A0A),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: center + Offset(r * 0.55, r * 0.14),
          width: r * 0.20,
          height: r * 0.32),
      Paint()..color = const Color(0xFF2A1A0A),
    );

    // Eyes
    final eyeY = center.dy + r * 0.04;
    canvas.drawCircle(Offset(center.dx - r * 0.20, eyeY), r * 0.07,
        Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawCircle(Offset(center.dx + r * 0.20, eyeY), r * 0.07,
        Paint()..color = const Color(0xFF2A1A0A));
    // Highlights
    canvas.drawCircle(Offset(center.dx - r * 0.17, eyeY - r * 0.03), r * 0.024,
        Paint()..color = Colors.white.withOpacity(0.80));
    canvas.drawCircle(Offset(center.dx + r * 0.23, eyeY - r * 0.03), r * 0.024,
        Paint()..color = Colors.white.withOpacity(0.80));

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
          center: center + Offset(0, r * 0.24),
          width: r * 0.46,
          height: r * 0.28),
      0.3,
      pi - 0.6,
      false,
      Paint()
        ..color = const Color(0xFF2A1A0A)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter _) => false;
}
