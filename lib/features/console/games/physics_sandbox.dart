import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

// ── Ball model ────────────────────────────────────────────────────────────────

class _Ball {
  Offset pos;
  Offset vel;
  final double r;
  final Color color;

  _Ball({required this.pos, required this.vel, required this.r, required this.color});
}

// ── Widget ────────────────────────────────────────────────────────────────────

class PhysicsSandbox extends StatefulWidget {
  const PhysicsSandbox({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<PhysicsSandbox> createState() => _PhysicsSandboxState();
}

class _PhysicsSandboxState extends State<PhysicsSandbox>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final List<_Ball> _balls = [];
  bool _gravity = true;
  int? _dragging; // index of dragged ball
  Offset _prevDrag = Offset.zero;
  Offset _dragVel = Offset.zero;

  static const _maxBalls = 40;
  static const _gravity0 = 400.0;
  static const _restitution = 0.80;
  static const _ballR = 14.0;

  final _rng = Random();
  static const _palette = [
    AppColors.violet,
    AppColors.cyan,
    AppColors.pink,
    AppColors.mint,
    AppColors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _spawnBall(Offset pos) {
    if (_balls.length >= _maxBalls) return;
    _balls.add(_Ball(
      pos: pos,
      vel: Offset((_rng.nextDouble() - 0.5) * 60, -_rng.nextDouble() * 40),
      r: _ballR + _rng.nextDouble() * 4,
      color: _palette[_rng.nextInt(_palette.length)],
    ));
  }

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033);
    _last = elapsed;
    _update(dt);
  }

  void _update(double dt) {
    final size = context.size;
    if (size == null || _balls.isEmpty) return;

    // Integrate (skip dragged ball)
    for (var i = 0; i < _balls.length; i++) {
      if (i == _dragging) continue;
      final b = _balls[i];
      if (_gravity) b.vel += Offset(0, _gravity0 * dt);
      b.pos += b.vel * dt;

      // Wall bounce
      if (b.pos.dx - b.r < 0) {
        b.pos = Offset(b.r, b.pos.dy);
        b.vel = Offset(-b.vel.dx * _restitution, b.vel.dy);
      }
      if (b.pos.dx + b.r > size.width) {
        b.pos = Offset(size.width - b.r, b.pos.dy);
        b.vel = Offset(-b.vel.dx * _restitution, b.vel.dy);
      }
      if (b.pos.dy - b.r < 0) {
        b.pos = Offset(b.pos.dx, b.r);
        b.vel = Offset(b.vel.dx, -b.vel.dy * _restitution);
      }
      if (b.pos.dy + b.r > size.height) {
        b.pos = Offset(b.pos.dx, size.height - b.r);
        b.vel = Offset(b.vel.dx, -b.vel.dy * _restitution);
        // Friction on floor
        b.vel = Offset(b.vel.dx * 0.96, b.vel.dy);
      }
    }

    // Ball-ball collisions (spec algorithm)
    for (var i = 0; i < _balls.length; i++) {
      for (var j = i + 1; j < _balls.length; j++) {
        final d = _balls[j].pos - _balls[i].pos;
        final dist = d.distance == 0 ? 0.0001 : d.distance;
        final overlap = _balls[i].r + _balls[j].r - dist;
        if (overlap > 0) {
          final n = d / dist;
          _balls[i].pos -= n * (overlap / 2);
          _balls[j].pos += n * (overlap / 2);
          final relVel = _balls[j].vel - _balls[i].vel;
          final sep = relVel.dx * n.dx + relVel.dy * n.dy;
          if (sep < 0) {
            final imp = n * sep;
            _balls[i].vel += imp;
            _balls[j].vel -= imp;
          }
        }
      }
    }

    if (mounted) setState(() {});
  }

  int? _ballAt(Offset pos) {
    for (var i = _balls.length - 1; i >= 0; i--) {
      if ((pos - _balls[i].pos).distance <= _balls[i].r + 6) return i;
    }
    return null;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pw = context.responsive<double>(mobile: double.infinity, tablet: 460, desktop: 480);
    return Center(
      child: SizedBox(
        width: pw == double.infinity ? MediaQuery.sizeOf(context).width - context.pageGutter * 2 : pw,
        height: 520,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corners.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE6060610),
                borderRadius: BorderRadius.circular(Corners.lg),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, 0),
                    child: Row(
                      children: [
                        Text('SANDBOX',
                            style: AppText.mono(size: 14, color: AppColors.amber, spacing: 2)),
                        const Spacer(),
                        Text('${_balls.length}/$_maxBalls balls',
                            style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.3)),
                        const SizedBox(width: Insets.md),
                        _ToggleChip(
                          label: _gravity ? 'Gravity ON' : 'Gravity OFF',
                          active: _gravity,
                          onTap: () => setState(() => _gravity = !_gravity),
                        ),
                        const SizedBox(width: Insets.sm),
                        _ToggleChip(
                          label: 'Clear',
                          active: false,
                          onTap: () => setState(() => _balls.clear()),
                        ),
                        const SizedBox(width: Insets.sm),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textTertiary, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  // Playfield
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (d) {
                        final hit = _ballAt(d.localPosition);
                        if (hit == null) _spawnBall(d.localPosition);
                      },
                      onPanStart: (d) {
                        final hit = _ballAt(d.localPosition);
                        if (hit != null) {
                          setState(() {
                            _dragging = hit;
                            _prevDrag = d.localPosition;
                            _dragVel = Offset.zero;
                            _balls[hit].vel = Offset.zero;
                          });
                        }
                      },
                      onPanUpdate: (d) {
                        if (_dragging == null) return;
                        final delta = d.localPosition - _prevDrag;
                        _dragVel = Offset.lerp(_dragVel, delta / 0.016, 0.4)!;
                        setState(() {
                          _balls[_dragging!].pos = d.localPosition;
                          _prevDrag = d.localPosition;
                        });
                      },
                      onPanEnd: (d) {
                        if (_dragging != null) {
                          _balls[_dragging!].vel = _dragVel * 55;
                          setState(() => _dragging = null);
                        }
                      },
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _SandboxPainter(balls: List.unmodifiable(_balls)),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tap to spawn  ·  Drag to fling  ·  Esc to exit',
                      style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SandboxPainter extends CustomPainter {
  const _SandboxPainter({required this.balls});
  final List<_Ball> balls;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in balls) {
      // Glow
      canvas.drawCircle(
        b.pos,
        b.r + 6,
        Paint()
          ..color = b.color.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Fill
      canvas.drawCircle(
        b.pos,
        b.r,
        Paint()..color = b.color.withValues(alpha: 0.85),
      );
      // Specular
      canvas.drawCircle(
        b.pos + Offset(-b.r * 0.25, -b.r * 0.28),
        b.r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_SandboxPainter old) => true;
}

// ── Small toggle chip ─────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.amber.withValues(alpha: 0.18) : AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(
            color: active ? AppColors.amber.withValues(alpha: 0.45) : AppColors.border,
          ),
        ),
        child: Text(label,
            style: AppText.mono(
                size: 10,
                color: active ? AppColors.amber : AppColors.textTertiary,
                spacing: 0.3)),
      ),
    );
  }
}
