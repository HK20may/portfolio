import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/data/models.dart';
import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/section_header.dart';

class ExperienceSection extends StatefulWidget {
  const ExperienceSection({super.key});

  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  final Key _key = UniqueKey();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.value = 1;
      _started = true;
    }
  }

  void _onVisible(VisibilityInfo info) {
    if (_started) return;
    if (info.visibleFraction >= 0.12) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const items = PortfolioData.experiences;

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
                eyebrow: 'experience',
                title: 'Where I\'ve built.',
                accent: AppColors.mint,
              ),
            ),
            const SizedBox(height: Insets.xxl),
            VisibilityDetector(
              key: _key,
              onVisibilityChanged: _onVisible,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _TimelineEntry(
                          exp: items[i],
                          progress:
                              _segment(i, items.length, _controller.value),
                          isLast: i == items.length - 1,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _segment(int i, int n, double p) {
    final start = i / (n + 1);
    final end = (i + 1.4) / (n + 1);
    return ((p - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.exp,
    required this.progress,
    required this.isLast,
  });
  final Experience exp;
  final double progress;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final railWidth = context.responsive<double>(mobile: 34, desktop: 48);

    return Stack(
      children: [
        // The rail fills the full height of the entry (card + bottom gap) so the
        // connecting line reaches the next node. No IntrinsicHeight required.
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: railWidth,
          child: CustomPaint(
            painter: _RailPainter(
              progress: progress,
              accent: exp.accent,
              isLast: isLast,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: railWidth),
          child: Opacity(
            opacity: Curves.easeOut.transform(progress),
            child: Transform.translate(
              offset: Offset(24 * (1 - progress), 0),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: Insets.xl,
                  left: Insets.sm,
                ),
                child: _ExperienceCard(exp: exp),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.progress,
    required this.accent,
    required this.isLast,
  });
  final double progress;
  final Color accent;
  final bool isLast;

  static const double nodeY = 10;
  static const double nodeR = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const lineTop = nodeY;
    final lineBottom = size.height;

    if (!isLast) {
      // Track
      final track = Paint()
        ..color = AppColors.border
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx, lineTop), Offset(cx, lineBottom), track);

      // Drawn (filled) portion
      final filledTo = lineTop + (lineBottom - lineTop) * progress;
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, accent.withOpacity(0.4)],
        ).createShader(Rect.fromLTRB(cx - 1, lineTop, cx + 1, lineBottom))
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx, lineTop), Offset(cx, filledTo), fill);
    }

    // Node
    final nodeActive = progress > 0.02;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = nodeActive ? accent : AppColors.borderStrong;
    canvas.drawCircle(Offset(cx, nodeY + nodeR), nodeR, ring);

    if (nodeActive) {
      final dot = Paint()..color = accent;
      canvas.drawCircle(
        Offset(cx, nodeY + nodeR),
        nodeR * 0.45 * Curves.easeOut.transform(progress),
        dot,
      );
      final glow = Paint()
        ..color = accent.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, nodeY + nodeR), nodeR, glow);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.exp});
  final Experience exp;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                exp.company,
                style: AppText.display(size: 24, weight: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: exp.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(Corners.pill),
                ),
                child: Text(
                  exp.period,
                  style: AppText.mono(size: 11, color: exp.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${exp.role}  ·  ${exp.location}',
            style: AppText.body(
              size: 15,
              weight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Insets.md),
          Text(
            exp.blurb,
            style: AppText.body(size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: Insets.lg),
          for (final h in exp.highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 12),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: exp.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      h,
                      style: AppText.body(
                        size: 14.5,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in exp.tags) TagPill(t, accent: exp.accent)
            ],
          ),
        ],
      ),
    );
  }
}
