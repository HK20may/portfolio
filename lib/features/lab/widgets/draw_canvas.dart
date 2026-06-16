import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

// ── Particle ──────────────────────────────────────────────────────────────────

class _Particle {
  Offset pos;
  Offset vel;
  double age; // 0→1 over lifetime
  final Color color;
  final double radius;

  _Particle({required this.pos, required this.vel, required this.color, required this.radius})
      : age = 0;

  bool get dead => age >= 1.0;
  double get alpha => (1 - age * age).clamp(0.0, 1.0);
  double get size => radius * (1 - age * 0.5);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class DrawCanvas extends StatefulWidget {
  const DrawCanvas({super.key});

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final List<_Particle> _particles = [];
  Offset? _prevPointer;
  int _hueIndex = 0;

  static const _maxParticles = 1800;
  static const _lifetime = 1.5; // seconds
  static const _emitSpacing = 5.0; // pixels between emissions
  static const _palette = [
    AppColors.violet,
    AppColors.cyan,
    AppColors.pink,
    AppColors.mint,
    AppColors.amber,
  ];
  static const _hueStep = 12; // particles per color

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033);
    _last = elapsed;

    bool any = false;
    for (final p in _particles) {
      p.age += dt / _lifetime;
      p.pos += p.vel * dt;
      if (!p.dead) any = true;
    }
    _particles.removeWhere((p) => p.dead);

    if (any || _particles.isNotEmpty) setState(() {});
  }

  void _emit(Offset pos) {
    if (_prevPointer != null) {
      // Fill in particles along the path
      final delta = pos - _prevPointer!;
      final dist = delta.distance;
      final steps = (dist / _emitSpacing).ceil().clamp(1, 30);
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        _addParticle(_prevPointer! + delta * t);
      }
    } else {
      _addParticle(pos);
    }
    _prevPointer = pos;
  }

  void _addParticle(Offset pos) {
    if (_particles.length >= _maxParticles) {
      _particles.removeRange(0, (_maxParticles * 0.1).ceil());
    }
    _hueIndex++;
    final color = _palette[(_hueIndex ~/ _hueStep) % _palette.length];
    final rng = Random();
    final angle = rng.nextDouble() * 2 * pi;
    final speed = 10 + rng.nextDouble() * 25;
    _particles.add(_Particle(
      pos: pos,
      vel: Offset(cos(angle) * speed, sin(angle) * speed),
      color: color,
      radius: 4 + rng.nextDouble() * 3,
    ));
  }

  void _clear() => setState(() {
        _particles.clear();
        _prevPointer = null;
      });

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = context.responsive<double>(mobile: 280, desktop: 380);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: h,
          // Listener is OUTSIDE ClipRRect so the clip region never intercepts
          // hit-tests, and all pointer events in the SizedBox area are captured.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _emit(e.localPosition),
            onPointerMove: (e) => _emit(e.localPosition),
            onPointerUp: (_) => _prevPointer = null,
            onPointerCancel: (_) => _prevPointer = null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x33060610),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: CustomPaint(
                  painter: _CanvasPainter(particles: List.unmodifiable(_particles)),
                  child: _particles.isEmpty
                      ? Center(
                          child: Text(
                            'Draw here',
                            style: AppText.mono(
                                size: 14,
                                color: AppColors.textTertiary.withValues(alpha: 0.4),
                                spacing: 2),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _clear,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Clear',
                style: AppText.mono(size: 11, color: AppColors.textSecondary, spacing: 0.5)),
          ),
        ),
      ],
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({required this.particles});
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = p.alpha;
      if (alpha <= 0) continue;

      // Glow
      canvas.drawCircle(
        p.pos,
        p.size + 5,
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Core
      canvas.drawCircle(
        p.pos,
        p.size,
        Paint()..color = p.color.withValues(alpha: alpha * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
