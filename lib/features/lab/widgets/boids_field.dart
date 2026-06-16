import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/cursor/cursor_scope.dart';

// ── Boid model ─────────────────────────────────────────────────────────────────

class _Boid {
  Offset pos;
  Offset vel;
  final Color color;

  _Boid({required this.pos, required this.vel, required this.color});
}

// ── Widget ─────────────────────────────────────────────────────────────────────

class BoidsField extends StatefulWidget {
  const BoidsField({super.key});

  @override
  State<BoidsField> createState() => _BoidsFieldState();
}

class _BoidsFieldState extends State<BoidsField> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _last = Duration.zero;
  List<_Boid> _boids = [];
  Size _size = Size.zero;

  static const _count = 120;
  static const _maxSpeed = 115.0;
  static const _minSpeed = 38.0;
  static const _neighborR = 80.0;
  static const _separationR = 24.0;
  static const _weights = (sep: 1.6, align: 1.0, coh: 0.7, cursor: 0.6);
  static const _maxForce = 65.0;

  static const _palette = [
    AppColors.violet,
    AppColors.cyan,
    AppColors.pink,
    AppColors.mint,
    AppColors.amber,
  ];

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _ticker?.stop();
    } else {
      if (_ticker?.isActive == false) _ticker?.start();
    }
  }

  void _ensureBoids(Size size) {
    if (_boids.isNotEmpty) return;
    _size = size;
    _boids = List.generate(_count, (_) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _minSpeed + _rng.nextDouble() * (_maxSpeed - _minSpeed) * 0.5;
      return _Boid(
        pos: Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: _palette[_rng.nextInt(_palette.length)],
      );
    });
  }

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033);
    _last = elapsed;
    if (_boids.isEmpty || _size == Size.zero) return;

    final cursorPos = CursorScope.maybeOf(context)?.position.value;
    _step(dt, cursorPos);
    if (mounted) setState(() {});
  }

  static Offset _limit(Offset v, double maxMag) {
    final d = v.distance;
    return d > maxMag && d > 0 ? v / d * maxMag : v;
  }

  Offset _wrap(Offset p) => Offset(
        (p.dx % _size.width + _size.width) % _size.width,
        (p.dy % _size.height + _size.height) % _size.height,
      );

  void _step(double dt, Offset? cursor) {
    final n = _boids.length;
    final newVels = List<Offset>.filled(n, Offset.zero);

    for (var i = 0; i < n; i++) {
      final b = _boids[i];
      var sepForce = Offset.zero;
      var alignSum = Offset.zero;
      var cohSum = Offset.zero;
      var neighbors = 0;

      for (var j = 0; j < n; j++) {
        if (j == i) continue;
        final other = _boids[j];
        // Use toroidal distance
        var dx = other.pos.dx - b.pos.dx;
        var dy = other.pos.dy - b.pos.dy;
        if (dx.abs() > _size.width / 2) dx -= _size.width * dx.sign;
        if (dy.abs() > _size.height / 2) dy -= _size.height * dy.sign;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < _neighborR) {
          neighbors++;
          alignSum += other.vel;
          cohSum += other.pos;
          if (dist < _separationR && dist > 0) {
            sepForce -= Offset(dx / (dist * dist), dy / (dist * dist));
          }
        }
      }

      var steer = Offset.zero;

      if (sepForce != Offset.zero) {
        steer += _limit(sepForce, _maxForce) * _weights.sep;
      }
      if (neighbors > 0) {
        final avgVel = alignSum / neighbors.toDouble();
        steer += _limit(avgVel - b.vel, _maxForce) * _weights.align;

        var cx = cohSum.dx / neighbors;
        var cy = cohSum.dy / neighbors;
        // Toroidal center correction
        if ((cx - b.pos.dx).abs() > _size.width / 2) cx -= _size.width * (cx - b.pos.dx).sign;
        if ((cy - b.pos.dy).abs() > _size.height / 2) cy -= _size.height * (cy - b.pos.dy).sign;
        steer += _limit(Offset(cx - b.pos.dx, cy - b.pos.dy), _maxForce) * _weights.coh;
      }

      // Cursor attraction
      if (cursor != null) {
        final toC = cursor - b.pos;
        if (toC.distance < 160) {
          steer += _limit(toC, _maxForce) * _weights.cursor;
        }
      }

      var newVel = b.vel + steer * dt;
      final spd = newVel.distance;
      if (spd > _maxSpeed) newVel = newVel / spd * _maxSpeed;
      if (spd < _minSpeed && spd > 0) newVel = newVel / spd * _minSpeed;
      newVels[i] = newVel;
    }

    for (var i = 0; i < n; i++) {
      _boids[i].vel = newVels[i];
      _boids[i].pos = _wrap(_boids[i].pos + _boids[i].vel * dt);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = context.responsive<double>(mobile: 280, desktop: 380);
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (ctx, c) {
        _ensureBoids(c.biggest);
        if (_size != c.biggest && _boids.isNotEmpty) {
          // Update stored size when layout changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _size = c.biggest);
          });
        }
        return RepaintBoundary(
          child: CustomPaint(
            painter: _BoidsPainter(
              boids: List.unmodifiable(_boids),
              reduceMotion: context.reduceMotion,
            ),
            size: c.biggest,
          ),
        );
      }),
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _BoidsPainter extends CustomPainter {
  const _BoidsPainter({required this.boids, required this.reduceMotion});
  final List<_Boid> boids;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in boids) {
      final angle = b.vel.distance > 0 ? atan2(b.vel.dy, b.vel.dx) : 0.0;
      _drawTriangle(canvas, b.pos, angle, b.color);
    }
  }

  void _drawTriangle(Canvas canvas, Offset pos, double angle, Color color) {
    const len = 8.0;
    const wing = 4.0;
    final nose = pos + Offset(cos(angle) * len, sin(angle) * len);
    final left = pos + Offset(cos(angle + 2.4) * wing, sin(angle + 2.4) * wing);
    final right = pos + Offset(cos(angle - 2.4) * wing, sin(angle - 2.4) * wing);

    final path = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_BoidsPainter old) => true;
}
