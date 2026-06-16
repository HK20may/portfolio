import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../game_input.dart';

enum _Gs { ready, playing, over }

class _Ship {
  Offset pos;
  Offset vel;
  double theta; // radians; 0 = right
  bool invuln;
  double invulnTimer;

  _Ship({required this.pos})
      : vel = Offset.zero,
        theta = -pi / 2,
        invuln = false,
        invulnTimer = 0;
}

class _Asteroid {
  Offset pos;
  Offset vel;
  final double radius;
  final int size; // 3 large, 2 medium, 1 small
  final List<double> radFrac; // per-vertex radius fractions
  double rotation;
  final double rotSpeed;

  _Asteroid({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.size,
    required this.radFrac,
    required this.rotSpeed,
  }) : rotation = 0;
}

class _Bullet {
  Offset pos;
  Offset vel;
  double life;
  _Bullet({required this.pos, required this.vel}) : life = 1.2;
}

// ── Main widget ───────────────────────────────────────────────────────────────

class AsteroidsGame extends StatefulWidget {
  const AsteroidsGame({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<AsteroidsGame> createState() => _AsteroidsGameState();
}

class _AsteroidsGameState extends State<AsteroidsGame>
    with SingleTickerProviderStateMixin, GameKeyboard<AsteroidsGame> {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  Size _field = const Size(440, 380);
  late _Ship _ship;
  final List<_Asteroid> _asteroids = [];
  final List<_Bullet> _bullets = [];

  int _score = 0;
  int _lives = 3;
  _Gs _gs = _Gs.ready;

  final _rng = Random();

  static const _bulletSpeed = 380.0;
  static const _accel = 200.0;
  static const _maxSpeed = 260.0;
  static const _turnSpeed = 2.6;
  static const _drag = 0.99;
  static const _fireRate = 0.25; // min seconds between shots
  double _fireCooldown = 0;

  @override
  void initState() {
    super.initState();
    initGameKeyboard();
    _ticker = createTicker(_tick)..start();
    _reset(startPlaying: false);
  }

  void _reset({bool startPlaying = false}) {
    _ship = _Ship(pos: Offset(_field.width / 2, _field.height / 2));
    _asteroids.clear();
    _bullets.clear();
    _score = 0;
    _lives = 3;
    _fireCooldown = 0;
    _gs = startPlaying ? _Gs.playing : _Gs.ready;
    _spawnWave(4);
    setState(() {});
  }

  void _spawnWave(int n) {
    for (var i = 0; i < n; i++) _spawnAsteroid(3, near: null);
  }

  void _spawnAsteroid(int size, {Offset? near}) {
    final radius = size == 3 ? 34.0 : size == 2 ? 20.0 : 10.0;
    final speed = (4.0 - size) * 30.0 + 20.0 + _rng.nextDouble() * 30;
    final angle = _rng.nextDouble() * 2 * pi;

    Offset pos;
    if (near != null) {
      final offset = Offset(cos(angle) * radius * 2, sin(angle) * radius * 2);
      pos = near + offset;
    } else {
      // Spawn on edge, away from ship
      final side = _rng.nextInt(4);
      pos = switch (side) {
        0 => Offset(_rng.nextDouble() * _field.width, 0),
        1 => Offset(_field.width, _rng.nextDouble() * _field.height),
        2 => Offset(_rng.nextDouble() * _field.width, _field.height),
        _ => Offset(0, _rng.nextDouble() * _field.height),
      };
    }

    final verts = 7 + _rng.nextInt(5);
    final radFrac = List.generate(verts, (_) => 0.65 + _rng.nextDouble() * 0.35);

    _asteroids.add(_Asteroid(
      pos: pos,
      vel: Offset(cos(angle) * speed, sin(angle) * speed),
      radius: radius,
      size: size,
      radFrac: radFrac,
      rotSpeed: (_rng.nextDouble() - 0.5) * 1.8,
    ));
  }

  @override
  void onGameKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return;
    }
    if (key == LogicalKeyboardKey.space) {
      if (_gs == _Gs.playing) {
        _tryFire();
      } else {
        _reset(startPlaying: true);
      }
    }
    if (key == LogicalKeyboardKey.keyR && _gs == _Gs.over) {
      _reset(startPlaying: true);
    }
  }

  void _tryFire() {
    if (_fireCooldown > 0) return;
    final dir = Offset(cos(_ship.theta), sin(_ship.theta));
    _bullets.add(_Bullet(
      pos: _ship.pos + dir * 14,
      vel: dir * _bulletSpeed + _ship.vel,
    ));
    _fireCooldown = _fireRate;
  }

  Offset _wrap(Offset p) => Offset(
        (p.dx % _field.width + _field.width) % _field.width,
        (p.dy % _field.height + _field.height) % _field.height,
      );

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_gs != _Gs.playing) return;
    _update(dt);
  }

  void _update(double dt) {
    // Rotate
    if (heldKeys.contains(LogicalKeyboardKey.arrowLeft)) _ship.theta -= _turnSpeed * dt;
    if (heldKeys.contains(LogicalKeyboardKey.arrowRight)) _ship.theta += _turnSpeed * dt;

    // Thrust
    final thrusting = heldKeys.contains(LogicalKeyboardKey.arrowUp);
    if (thrusting) {
      final dir = Offset(cos(_ship.theta), sin(_ship.theta));
      _ship.vel += dir * _accel * dt;
      final spd = _ship.vel.distance;
      if (spd > _maxSpeed) _ship.vel = _ship.vel / spd * _maxSpeed;
    }

    // Drag
    final dragFactor = pow(_drag, dt * 60).toDouble();
    _ship.vel = Offset(_ship.vel.dx * dragFactor, _ship.vel.dy * dragFactor);

    _ship.pos = _wrap(_ship.pos + _ship.vel * dt);

    // Invuln
    if (_ship.invuln) {
      _ship.invulnTimer -= dt;
      if (_ship.invulnTimer <= 0) _ship.invuln = false;
    }

    // Fire cooldown
    if (_fireCooldown > 0) _fireCooldown -= dt;

    // Auto-fire while space held
    if (heldKeys.contains(LogicalKeyboardKey.space)) _tryFire();

    // Asteroids
    for (final a in _asteroids) {
      a.pos = _wrap(a.pos + a.vel * dt);
      a.rotation += a.rotSpeed * dt;
    }

    // Bullets
    _bullets.removeWhere((b) {
      b.pos = _wrap(b.pos + b.vel * dt);
      b.life -= dt;
      return b.life <= 0;
    });

    // Bullet × asteroid
    final hitAsteroids = <_Asteroid>{};
    final hitBullets = <_Bullet>{};
    for (final b in _bullets) {
      for (final a in _asteroids) {
        if (hitAsteroids.contains(a) || hitBullets.contains(b)) continue;
        if ((b.pos - a.pos).distance < a.radius) {
          hitBullets.add(b);
          hitAsteroids.add(a);
          _score += (4 - a.size) * 10;
        }
      }
    }
    _bullets.removeWhere(hitBullets.contains);
    for (final a in hitAsteroids) {
      _asteroids.remove(a);
      if (a.size > 1) {
        _spawnAsteroid(a.size - 1, near: a.pos);
        _spawnAsteroid(a.size - 1, near: a.pos);
      }
    }

    // Ship × asteroid
    if (!_ship.invuln) {
      for (final a in _asteroids) {
        if ((_ship.pos - a.pos).distance < a.radius + 8) {
          _lives--;
          if (_lives <= 0) {
            setState(() => _gs = _Gs.over);
            return;
          }
          _ship.pos = Offset(_field.width / 2, _field.height / 2);
          _ship.vel = Offset.zero;
          _ship.invuln = true;
          _ship.invulnTimer = 2.2;
          break;
        }
      }
    }

    // New wave
    if (_asteroids.isEmpty) _spawnWave(4 + (_score ~/ 200).clamp(0, 6));

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    disposeGameKeyboard();
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
              child: Focus(
                focusNode: gameFocus,
                autofocus: true,
                onKeyEvent: handleGameKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, 0),
                      child: Row(
                        children: [
                          Text('ASTEROIDS',
                              style: AppText.mono(size: 14, color: AppColors.cyan, spacing: 2)),
                          const Spacer(),
                          Text('♥ × $_lives   score: $_score',
                              style: AppText.mono(size: 12, color: AppColors.textSecondary, spacing: 0.5)),
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
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, c) {
                        _field = c.biggest;
                        return RepaintBoundary(
                          child: CustomPaint(
                            painter: _AsteroidsPainter(
                              ship: _ship,
                              asteroids: List.unmodifiable(_asteroids),
                              bullets: List.unmodifiable(_bullets),
                              gs: _gs,
                              score: _score,
                              thrusting: heldKeys.contains(LogicalKeyboardKey.arrowUp),
                            ),
                            size: c.biggest,
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '← → rotate  ·  ↑ thrust  ·  Space fire  ·  Esc exit',
                        style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _AsteroidsPainter extends CustomPainter {
  const _AsteroidsPainter({
    required this.ship,
    required this.asteroids,
    required this.bullets,
    required this.gs,
    required this.score,
    required this.thrusting,
  });

  final _Ship ship;
  final List<_Asteroid> asteroids;
  final List<_Bullet> bullets;
  final _Gs gs;
  final int score;
  final bool thrusting;

  static final _rng = Random();

  @override
  void paint(Canvas canvas, Size size) {
    _drawAsteroids(canvas);
    _drawBullets(canvas);
    if (gs != _Gs.ready || true) _drawShip(canvas, size);
    if (gs == _Gs.ready) _drawMsg(canvas, size, 'Space / R to start', AppColors.textSecondary);
    if (gs == _Gs.over) {
      _drawMsg(canvas, size, 'Game Over', AppColors.pink);
      _drawSub(canvas, size, 'Score: $score   Space / R to restart', AppColors.textTertiary);
    }
  }

  void _drawShip(Canvas canvas, Size size) {
    if (ship.invuln && ((ship.invulnTimer * 8).floor() % 2 == 0)) return; // blink

    final cos0 = cos(ship.theta);
    final sin0 = sin(ship.theta);
    final nose = ship.pos + Offset(cos0 * 13, sin0 * 13);
    final left = ship.pos + Offset(cos(ship.theta + 2.4) * 9, sin(ship.theta + 2.4) * 9);
    final right = ship.pos + Offset(cos(ship.theta - 2.4) * 9, sin(ship.theta - 2.4) * 9);

    final path = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = AppColors.auroraGradient.createShader(
            Rect.fromCenter(center: ship.pos, width: 28, height: 28))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Thrust flame
    if (thrusting) {
      final backDir = Offset(cos(ship.theta + pi), sin(ship.theta + pi));
      final backBase = ship.pos + backDir * 5;
      final flameLen = 8.0 + _rng.nextDouble() * 6;
      final flameTip = ship.pos + backDir * flameLen;
      canvas.drawLine(
        backBase,
        flameTip,
        Paint()
          ..color = AppColors.amber.withValues(alpha: 0.85)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawAsteroids(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final a in asteroids) {
      final n = a.radFrac.length;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = a.rotation + (2 * pi * i / n);
        final r = a.radius * a.radFrac[i];
        final p = a.pos + Offset(cos(angle) * r, sin(angle) * r);
        if (i == 0) path.moveTo(p.dx, p.dy);
        else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawBullets(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.cyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final b in bullets) {
      canvas.drawCircle(b.pos, 2.5, paint);
    }
  }

  void _drawMsg(Canvas canvas, Size s, String text, Color c) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 20, color: c, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: s.width);
    tp.paint(canvas, Offset((s.width - tp.width) / 2, s.height / 2 - 20));
  }

  void _drawSub(Canvas canvas, Size s, String text, Color c) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: s.width);
    tp.paint(canvas, Offset((s.width - tp.width) / 2, s.height / 2 + 10));
  }

  @override
  bool shouldRepaint(_AsteroidsPainter old) => true;
}
