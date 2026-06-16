import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive ripple field — click or drag to emit expanding ripples that
/// displace and brighten the dot grid as the wavefront passes.
/// Pointer hover gently lifts nearby dots. Cap: 6 concurrent ripples.
/// Static grid under reduced motion.
class DotMatrix extends StatefulWidget {
  const DotMatrix({super.key});

  @override
  State<DotMatrix> createState() => _DotMatrixState();
}

class _DotMatrixState extends State<DotMatrix>
    with SingleTickerProviderStateMixin {
  Offset _pointer = const Offset(-9999, -9999);
  final List<_Dot> _dots = [];
  final List<_Ripple> _ripples = [];
  Ticker? _ticker;
  Size _size = Size.zero;

  static const _spacing = 28.0;
  static const _hoverFalloff = 120.0;
  static const _maxRipples = 6;
  static const _rippleSpeed = 130.0; // px per second

  static final _rippleColors = [
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

  void _buildGrid(Size size) {
    if (size == _size && _dots.isNotEmpty) return;
    _size = size;
    _dots.clear();
    _ripples.clear();
    final cols = (size.width / _spacing).floor();
    final rows = (size.height / _spacing).floor();
    final ox = (size.width - (cols - 1) * _spacing) / 2;
    final oy = (size.height - (rows - 1) * _spacing) / 2;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        _dots.add(_Dot(Offset(ox + c * _spacing, oy + r * _spacing)));
      }
    }
  }

  void _emitRipple(Offset pos) {
    if (_ripples.length >= _maxRipples) _ripples.removeAt(0);
    _ripples.add(_Ripple(
      origin: pos,
      color: _rippleColors[_ripples.length % _rippleColors.length],
    ));
  }

  void _tick(Duration _) {
    // Update ripples
    for (final r in _ripples) {
      r.radius += _rippleSpeed * 0.016;
      r.amplitude = max(0.0, r.amplitude - 0.012);
    }
    _ripples.removeWhere((r) => r.amplitude < 0.01);

    bool dirty = false;
    for (final d in _dots) {
      // Hover push
      final hDist = (_pointer - d.rest).distance;
      final hT = (1 - (hDist / _hoverFalloff).clamp(0.0, 1.0));
      Offset target = d.rest;
      if (hT > 0.01) {
        target = d.rest +
            (d.rest - _pointer) / max(hDist, 1) * hT * 24;
      }

      // Ripple displacement
      for (final r in _ripples) {
        final dist = (d.rest - r.origin).distance;
        final diff = dist - r.radius;
        final wave = exp(-(diff * diff) / 180.0) * r.amplitude;
        if (wave > 0.005) {
          final dir = d.rest - r.origin;
          final len = dir.distance;
          final norm = len > 0 ? dir / len : Offset.zero;
          target += norm * wave * 18;
        }
      }

      final next = Offset.lerp(d.current, target, 0.14)!;
      if ((next - d.current).distance > 0.2) {
        d.current = next;
        dirty = true;
      }
    }

    if (dirty || _ripples.isNotEmpty) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = context.responsive<double>(mobile: 260, desktop: 360);

    if (context.reduceMotion) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            _buildGrid(constraints.biggest);
            return CustomPaint(
              painter: _RipplePainter(
                dots: _dots,
                ripples: const [],
                pointer: const Offset(-9999, -9999),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: h,
      width: double.infinity,
      child: MouseRegion(
        onExit: (_) => setState(() => _pointer = const Offset(-9999, -9999)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (e) => _emitRipple(e.localPosition),
          onPanStart: (e) => _emitRipple(e.localPosition),
          onPanUpdate: (e) {
            _pointer = e.localPosition;
            if (e.delta.distance > 8) _emitRipple(e.localPosition);
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerHover: (e) =>
                setState(() => _pointer = e.localPosition),
            onPointerMove: (e) =>
                setState(() => _pointer = e.localPosition),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                _buildGrid(constraints.biggest);
                return CustomPaint(
                  painter: _RipplePainter(
                    dots: _dots,
                    ripples: _ripples,
                    pointer: _pointer,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _Dot {
  _Dot(this.rest) : current = rest;
  final Offset rest;
  Offset current;
}

class _Ripple {
  _Ripple({required this.origin, required this.color});
  final Offset origin;
  final Color color;
  double radius = 0;
  double amplitude = 1.0;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.dots,
    required this.ripples,
    required this.pointer,
  });

  final List<_Dot> dots;
  final List<_Ripple> ripples;
  final Offset pointer;

  static const _hoverFalloff = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint expanding rings
    for (final r in ripples) {
      canvas.drawCircle(
        r.origin,
        r.radius,
        Paint()
          ..color = r.color.withValues(alpha: r.amplitude * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Dots
    for (final d in dots) {
      final hDist = (pointer - d.rest).distance;
      final hT = (1 - (hDist / _hoverFalloff).clamp(0.0, 1.0));

      double rIntensity = 0;
      Color dotColor = AppColors.textTertiary;
      for (final r in ripples) {
        final dist = (d.rest - r.origin).distance;
        final diff = dist - r.radius;
        final wave = exp(-(diff * diff) / 180.0) * r.amplitude;
        if (wave > rIntensity) {
          rIntensity = wave;
          dotColor = r.color;
        }
      }

      final t = (hT + rIntensity * 0.5).clamp(0.0, 1.0);
      final radius = 2.0 + t * 3.5;
      final alpha = 0.22 + t * 0.7;
      final color = Color.lerp(AppColors.textTertiary, dotColor, t)!
          .withValues(alpha: alpha);

      canvas.drawCircle(d.current, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => true;
}
