import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launch.dart';
import '../../../shared/widgets/magnetic_button.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/social_row.dart';
import '../../../state/navigation_cubit.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key, required this.onNavigate});
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    final headlineSize = context.responsive<double>(
      mobile: 40,
      tablet: 60,
      desktop: 78,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.pageGutter,
        context.responsive(mobile: Insets.xxl, desktop: Insets.xxxl),
        context.pageGutter,
        Insets.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnScroll(
              child: Text('// contact',
                  style: AppText.mono(color: AppColors.violet)),
            ),
            const SizedBox(height: Insets.lg),
            RevealOnScroll(
              delay: const Duration(milliseconds: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [AppColors.textPrimary, AppColors.textPrimary],
                  ).createShader(r),
                  child: Text(
                    'Let\'s build something people love to use.',
                    style: AppText.display(
                      size: headlineSize,
                      weight: FontWeight.w800,
                      height: 1.02,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
            RevealOnScroll(
              delay: const Duration(milliseconds: 120),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'Have a product that deserves to feel fast and alive? I\'m '
                  'open to new roles and collaborations.',
                  style: AppText.body(size: 17, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: Insets.xl),
            RevealOnScroll(
              delay: const Duration(milliseconds: 160),
              child: Wrap(
                spacing: Insets.lg,
                runSpacing: Insets.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ConfettiSayHello(email: profile.email),
                  GestureDetector(
                    onTap: () => openUrl('mailto:${profile.email}'),
                    child: MouseRegion(
                      cursor: context.usePointerInteractions
                          ? SystemMouseCursors.none
                          : SystemMouseCursors.click,
                      child: Text(
                        profile.email,
                        style: AppText.body(
                          size: 17,
                          weight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xxl),
            RevealOnScroll(
              delay: const Duration(milliseconds: 200),
              child: SocialRow(links: profile.socials, fontSize: 17),
            ),
            const SizedBox(height: Insets.xxl),
            const _Divider(),
            const SizedBox(height: Insets.lg),
            _Footer(onBackToTop: () => onNavigate(Section.hero)),
          ],
        ),
      ),
    );
  }
}

// ── Confetti burst on "Say hello" ─────────────────────────────────────────────

class _ConfettiSayHello extends StatefulWidget {
  const _ConfettiSayHello({required this.email});
  final String email;

  @override
  State<_ConfettiSayHello> createState() => _ConfettiSayHelloState();
}

class _ConfettiSayHelloState extends State<_ConfettiSayHello> {
  OverlayEntry? _entry;

  void _burst() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset(box.size.width / 2, 0));

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _ConfettiOverlay(
        origin: origin,
        onDone: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MagneticButton(
      label: 'Say hello',
      filled: true,
      icon: Icons.arrow_outward_rounded,
      onPressed: () {
        openUrl('mailto:${widget.email}');
        _burst();
      },
    );
  }
}

class _ConfettiParticle {
  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  double rot;
  final double rotSpeed;
  double life; // 1→0

  _ConfettiParticle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.rot,
    required this.rotSpeed,
  }) : life = 1.0;
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.origin, required this.onDone});
  final Offset origin;
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late List<_ConfettiParticle> _particles;

  static const _colors = [
    AppColors.violet,
    AppColors.cyan,
    AppColors.pink,
    AppColors.mint,
    AppColors.amber,
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(60, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 80 + rng.nextDouble() * 220;
      return _ConfettiParticle(
        pos: widget.origin,
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 180),
        color: _colors[rng.nextInt(_colors.length)],
        size: 4 + rng.nextDouble() * 5,
        rot: rng.nextDouble() * 2 * pi,
        rotSpeed: (rng.nextDouble() - 0.5) * 10,
      );
    });
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;

    var allDone = true;
    for (final p in _particles) {
      p.vel += Offset(0, 340 * dt); // gravity
      p.pos += p.vel * dt;
      p.rot += p.rotSpeed * dt;
      p.life -= dt / 1.5;
      if (p.life > 0) allDone = false;
    }

    if (allDone) {
      widget.onDone();
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(particles: List.unmodifiable(_particles)),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles});
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color.withValues(alpha: alpha * 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onBackToTop});
  final VoidCallback onBackToTop;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: Insets.md,
      children: [
        Text(
          '© $year Harshit Kumawat',
          style: AppText.mono(size: 12, color: AppColors.textTertiary),
        ),
        Text(
          'Designed & built in Flutter — shader + motion by hand',
          style: AppText.mono(size: 12, color: AppColors.textTertiary),
        ),
        GestureDetector(
          onTap: onBackToTop,
          child: MouseRegion(
            cursor: context.usePointerInteractions
                ? SystemMouseCursors.none
                : SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Back to top', style: AppText.mono(size: 12)),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
