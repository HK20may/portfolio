import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A faint, static film grain laid over the whole scene. Deterministic and
/// painted once (no per-frame cost) — just enough to kill the flatness of
/// large gradient fields.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, this.opacity = 0.035, this.density = 0.18});

  final double opacity;
  final double density;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(opacity: opacity, density: density),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity, required this.density});
  final double opacity;
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final count = (size.width * size.height * density / 1000).clamp(0, 9000).toInt();
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}
