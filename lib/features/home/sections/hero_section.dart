import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/data/models.dart';
import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/cursor/cursor_scope.dart';
import '../../../shared/widgets/kinetic_text.dart';
import '../../../shared/widgets/magnetic_button.dart';
import '../../../shared/widgets/particle_field.dart';
import '../../../shared/widgets/phone_frame.dart';
import '../../../shared/widgets/scroll_cue.dart';
import '../../../shared/widgets/tilt_card.dart';
import '../../../shared/widgets/typing_text.dart';
import '../../../state/console_cubit.dart';
import '../../../state/navigation_cubit.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.play,
    required this.onNavigate,
  });

  final bool play;
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    final nameSize = context.responsive<double>(
      mobile: 46,
      tablet: 76,
      desktop: 104,
    );

    final cursor = CursorScope.maybeOf(context);
    final isDesktop = context.isDesktop;

    final textColumn = _HeroParallax(
      child: _HeroText(
        profile: profile,
        nameSize: nameSize,
        play: play,
        onNavigate: onNavigate,
      ),
    );

    return Stack(
      children: [
        // Ambient constellation — ignored by pointer
        if (!context.reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: ParticleField(
                count: context.responsive<int>(mobile: 35, desktop: 70),
                opacity: 0.45,
                connectLines: true,
                reactRadius: 130.0,
                cursorNotifier: cursor?.position,
              ),
            ),
          ),
        Container(
          constraints: BoxConstraints(minHeight: context.screenHeight),
          padding: EdgeInsets.fromLTRB(
            context.pageGutter,
            context.screenHeight * 0.16,
            isDesktop ? 48 : context.pageGutter,
            Insets.xxl,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: textColumn),
                    const SizedBox(width: Insets.xl),
                    const _HeroPhone(),
                    const SizedBox(width: 48),
                  ],
                )
              : textColumn,
        ),
      ],
    );
  }
}

// ── Hero text column ───────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.profile,
    required this.nameSize,
    required this.play,
    required this.onNavigate,
  });

  final Profile profile;
  final double nameSize;
  final bool play;
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability + metric chips
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: const [
            _AvailabilityPill(),
            _CountUpChip(),
          ],
        ),
        const SizedBox(height: Insets.xl),
        // Kinetic name
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: KineticText(
            profile.name,
            play: play,
            startDelay: const Duration(milliseconds: 120),
            style: AppText.display(
              size: nameSize,
              weight: FontWeight.w800,
              height: 0.98,
              spacing: -2,
              shadows: const [
                Shadow(
                  color: Color(0xB3000000),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        _RoleCycler(roles: profile.roles, play: play),
        const SizedBox(height: Insets.md),
        // Typing tagline
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: TypingText(
            phrases: const [
              'shipping cross-platform apps to millions',
              'Flutter · motion · now full-stack',
              'every project here is playable →',
            ],
            style: AppText.body(
              size: context.responsive<double>(mobile: 16, desktop: 19),
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: Insets.xl),
        // CTAs + ⌘K hint
        Wrap(
          spacing: Insets.md,
          runSpacing: Insets.md,
          children: [
            MagneticButton(
              label: 'View work',
              filled: true,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => onNavigate(Section.work),
            ),
            MagneticButton(
              label: 'Get in touch',
              onPressed: () => onNavigate(Section.contact),
            ),
            const _CmdKPill(),
          ],
        ),
        SizedBox(
            height: context.responsive<double>(
                mobile: Insets.xxl, desktop: 96)),
        const ScrollCue(),
      ],
    );
  }
}

// ── Cycling hero showcase (desktop only) ──────────────────────────────────────

class _HeroPhone extends StatelessWidget {
  const _HeroPhone();

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      glareColor: AppColors.violet,
      maxTilt: 0.08,
      onTap: () => context.go('/lab'),
      child: const PhoneFrame(
        width: 210,
        child: _HeroShowcase(),
      ),
    );
  }
}

class _HeroShowcase extends StatefulWidget {
  const _HeroShowcase();

  @override
  State<_HeroShowcase> createState() => _HeroShowcaseState();
}

class _HeroShowcaseState extends State<_HeroShowcase> {
  static const _labels = ['Realtime data', 'Sorting', 'Pathfinding'];
  int _idx = 0;
  Timer? _cycleTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.reduceMotion) {
      _cycleTimer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
        if (mounted) setState(() => _idx = (_idx + 1) % _labels.length);
      });
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_idx),
                child: _buildPreview(_idx),
              ),
            ),
          ),
          // Caption strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  _labels[_idx],
                  style: AppText.mono(
                      size: 9, color: AppColors.textSecondary, spacing: 0),
                ),
                const Spacer(),
                // Page dots
                Row(
                  children: [
                    for (var i = 0; i < _labels.length; i++)
                      Container(
                        width: i == _idx ? 14 : 5,
                        height: 5,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          color: i == _idx
                              ? AppColors.violet
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPreview(int idx) {
    switch (idx) {
      case 0: return const _PreviewChart();
      case 1: return const _PreviewBars();
      default: return const _PreviewGrid();
    }
  }
}

// ── Mini preview: scrolling line chart ────────────────────────────────────────

class _PreviewChart extends StatefulWidget {
  const _PreviewChart();
  @override
  State<_PreviewChart> createState() => _PreviewChartState();
}

class _PreviewChartState extends State<_PreviewChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BTC ₹', style: AppText.mono(size: 9, color: AppColors.cyan, spacing: 0)),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => RepaintBoundary(
                child: CustomPaint(
                  painter: _MiniChartPainter(phase: _ctrl.value, color: AppColors.cyan),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('ETH ₹', style: AppText.mono(size: 9, color: AppColors.violet, spacing: 0)),
          const SizedBox(height: 4),
          SizedBox(
            height: 50,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => RepaintBoundary(
                child: CustomPaint(
                  painter: _MiniChartPainter(
                      phase: _ctrl.value + 0.3, color: AppColors.violet, freq: 0.7),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  const _MiniChartPainter(
      {required this.phase, required this.color, this.freq = 1.0});
  final double phase;
  final Color color;
  final double freq;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = 40;
    final path = Path();
    for (var i = 0; i <= pts; i++) {
      final x = i / pts * size.width;
      final t = i / pts * 2 * pi * freq + phase * 2 * pi;
      final y =
          size.height * 0.5 - sin(t) * size.height * 0.3 - cos(t * 1.7) * size.height * 0.12;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    // Fill
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.10));
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) => old.phase != phase;
}

// ── Mini preview: sorting bars ────────────────────────────────────────────────

class _PreviewBars extends StatefulWidget {
  const _PreviewBars();
  @override
  State<_PreviewBars> createState() => _PreviewBarsState();
}

class _PreviewBarsState extends State<_PreviewBars>
    with SingleTickerProviderStateMixin {
  static const _vals = [42, 78, 23, 91, 55, 38, 67, 14, 83, 29];
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sorting', style: AppText.mono(size: 9, color: AppColors.amber, spacing: 0)),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = _ctrl.value;
                final n = _vals.length;
                // Cycle highlight through bar pairs
                final pos = (t * n * 2).floor() % (n - 1);
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: _MiniBarPainter(
                      vals: _vals,
                      highlightA: pos,
                      highlightB: pos + 1,
                      swapped: t.floor() % 2 == 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarPainter extends CustomPainter {
  const _MiniBarPainter({
    required this.vals,
    required this.highlightA,
    required this.highlightB,
    required this.swapped,
  });
  final List<int> vals;
  final int highlightA, highlightB;
  final bool swapped;

  @override
  void paint(Canvas canvas, Size size) {
    final n = vals.length;
    final maxV = vals.reduce(max).toDouble();
    final bw = size.width / n;
    const gap = 3.0;
    for (var i = 0; i < n; i++) {
      final h = vals[i] / maxV * size.height;
      final Color c;
      if (i == highlightA || i == highlightB) {
        c = swapped ? AppColors.pink : AppColors.amber;
      } else {
        c = AppColors.violet.withOpacity(0.5);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * bw + gap / 2, size.height - h, bw - gap, h),
          const Radius.circular(2),
        ),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniBarPainter old) =>
      old.highlightA != highlightA || old.swapped != swapped;
}

// ── Mini preview: pathfinding grid ────────────────────────────────────────────

class _PreviewGrid extends StatefulWidget {
  const _PreviewGrid();
  @override
  State<_PreviewGrid> createState() => _PreviewGridState();
}

class _PreviewGridState extends State<_PreviewGrid>
    with SingleTickerProviderStateMixin {
  static const _rows = 6;
  static const _cols = 8;
  // A simple pre-drawn path from (0,0) to (5,7) for the mini preview
  static const _path = [
    (0, 0), (0, 1), (1, 1), (1, 2), (2, 2), (2, 3),
    (3, 3), (3, 4), (4, 4), (4, 5), (5, 5), (5, 6), (5, 7),
  ];
  static const _walls = {(1, 0), (2, 1), (3, 2), (4, 3)};

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A* search', style: AppText.mono(size: 9, color: AppColors.mint, spacing: 0)),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final revealed = (_ctrl.value * _path.length).floor().clamp(0, _path.length);
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: _MiniGridPainter(
                      rows: _rows,
                      cols: _cols,
                      path: _path.take(revealed).toList(),
                      walls: _walls,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  const _MiniGridPainter(
      {required this.rows, required this.cols, required this.path, required this.walls});
  final int rows, cols;
  final List<(int, int)> path;
  final Set<(int, int)> walls;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    const gap = 1.5;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = (r, c);
        Color color;
        if (r == 0 && c == 0) {
          color = AppColors.mint;
        } else if (r == rows - 1 && c == cols - 1) {
          color = AppColors.pink;
        } else if (path.contains(cell)) {
          color = AppColors.cyan;
        } else if (walls.contains(cell)) {
          color = const Color(0xFF1E1E2E);
        } else {
          color = const Color(0xFF151520);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cw + gap, r * ch + gap, cw - gap * 2, ch - gap * 2),
            const Radius.circular(2),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) => old.path.length != path.length;
}

// ── Parallax ───────────────────────────────────────────────────────────────────

/// Translates the hero content opposite the cursor for a gentle parallax feel.
/// Only active on pointer devices; collapses to Offset.zero on touch/reduceMotion.
///
/// IMPORTANT: always returns the same widget tree shape (ValueListenableBuilder →
/// Transform → child) so that KineticText's element is never remounted when the
/// viewport width crosses the pointer-device breakpoint.
class _HeroParallax extends StatelessWidget {
  const _HeroParallax({required this.child});
  final Widget child;

  static final ValueNotifier<Offset> _zero = ValueNotifier(Offset.zero);

  @override
  Widget build(BuildContext context) {
    final position = CursorScope.maybeOf(context)?.position ?? _zero;
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, pos, innerChild) {
        final Offset offset;
        if (!context.usePointerInteractions ||
            MediaQuery.of(context).disableAnimations) {
          offset = Offset.zero;
        } else {
          final size = MediaQuery.sizeOf(context);
          offset = Offset(
            (pos.dx / size.width - 0.5) * -10.0,
            (pos.dy / size.height - 0.5) * -8.0,
          );
        }
        return Transform.translate(offset: offset, child: innerChild);
      },
      child: child,
    );
  }
}

// ── Availability pill ──────────────────────────────────────────────────────────

class _AvailabilityPill extends StatefulWidget {
  const _AvailabilityPill();

  @override
  State<_AvailabilityPill> createState() => _AvailabilityPillState();
}

class _AvailabilityPillState extends State<_AvailabilityPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withOpacity(0.6 * _pulse.value),
                      blurRadius: 8,
                      spreadRadius: 2 * _pulse.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            'Available for new work',
            style: AppText.mono(size: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Count-up metric chip ───────────────────────────────────────────────────────

class _CountUpChip extends StatefulWidget {
  const _CountUpChip();

  @override
  State<_CountUpChip> createState() => _CountUpChipState();
}

class _CountUpChipState extends State<_CountUpChip> {
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('hero-metric-chip'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.4 && !_triggered) {
          setState(() => _triggered = true);
        }
      },
      child: TweenAnimationBuilder<double>(
        duration: context.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 1400),
        tween: Tween(begin: 0.0, end: _triggered ? 1.0 : 0.0),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) {
          final count = (t * 1000000).round();
          final label =
              count >= 1000000 ? '1M+' : '${(count / 1000).round()}K+';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(Corners.pill),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '$label downloads shipped',
                  style: AppText.mono(
                      size: 12, color: AppColors.textSecondary, spacing: 0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── ⌘K hint pill ──────────────────────────────────────────────────────────────

class _CmdKPill extends StatelessWidget {
  const _CmdKPill();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ConsoleCubit>().togglePalette(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_command_key_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Text('K',
                  style: AppText.mono(
                      size: 12, color: AppColors.textTertiary, spacing: 0)),
              const SizedBox(width: 6),
              Text('command palette',
                  style: AppText.mono(
                      size: 12, color: AppColors.textTertiary, spacing: 0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role cycler ────────────────────────────────────────────────────────────────

class _RoleCycler extends StatefulWidget {
  const _RoleCycler({required this.roles, required this.play});
  final List<String> roles;
  final bool play;

  @override
  State<_RoleCycler> createState() => _RoleCyclerState();
}

class _RoleCyclerState extends State<_RoleCycler> {
  int _index = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _RoleCycler old) {
    super.didUpdateWidget(old);
    if (widget.play && _timer == null) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && _timer == null) _start();
  }

  void _start() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % widget.roles.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size =
        context.responsive<double>(mobile: 22, tablet: 28, desktop: 32);
    return Row(
      children: [
        Container(
          width: 28,
          height: 2,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            gradient: AppColors.subtleGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: Motion.med,
            transitionBuilder: (child, anim) => ClipRect(
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
            ),
            child: Text(
              widget.roles[_index],
              key: ValueKey(_index),
              style: AppText.display(
                size: size,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
