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
  static const _neighborR = 58.0;
  static const _sepR = 26.0;
  static const _maxSpeed = 78.0;
  static const _minSpeed = 30.0;
  static const _accel = 220.0;
  static const _wSep = 1.8, _wAli = 0.9, _wCoh = 0.65, _wCursor = 0.45;

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

  static Offset _norm(Offset v) {
    final d = v.distance;
    return d == 0 ? Offset.zero : v / d;
  }

  Offset _wrap(Offset p) => Offset(
        (p.dx % _size.width + _size.width) % _size.width,
        (p.dy % _size.height + _size.height) % _size.height,
      );

  void _step(double dt, Offset? cursor) {
    for (final b in _boids) {
      var sep = Offset.zero;
      var aliSum = Offset.zero;
      var cohSum = Offset.zero;
      var nNbr = 0, nSep = 0;

      for (final o in _boids) {
        if (identical(o, b)) continue;
        final d = b.pos - o.pos;
        final dist = d.distance;
        if (dist > 0 && dist < _neighborR) {
          aliSum += o.vel;
          cohSum += o.pos;
          nNbr++;
          if (dist < _sepR) {
            sep += d / (dist * dist);
            nSep++;
          }
        }
      }

      var steer = Offset.zero;
      if (nSep > 0) steer += _norm(sep) * _wSep;
      if (nNbr > 0) {
        steer += _norm(aliSum / nNbr.toDouble() - b.vel) * _wAli;
        steer += _norm(cohSum / nNbr.toDouble() - b.pos) * _wCoh;
      }
      if (cursor != null) steer += _norm(cursor - b.pos) * _wCursor;

      b.vel += steer * _accel * dt;
      final spd = b.vel.distance;
      if (spd > _maxSpeed) b.vel = b.vel / spd * _maxSpeed;
      if (spd < _minSpeed && spd > 0) b.vel = b.vel / spd * _minSpeed;
      b.pos = _wrap(b.pos + b.vel * dt);
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
