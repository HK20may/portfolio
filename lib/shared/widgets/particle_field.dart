import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';

/// A Ticker-driven particle system with optional cursor interaction.
///
/// Parameters:
///  - [count]       — number of particles (default 100)
///  - [opacity]     — overall opacity multiplier (default 1.0)
///  - [connectLines]— draw faint lines between nearby particles (default true)
///  - [reactRadius] — radius within which particles react to the pointer
///  - [height]      — explicit canvas height; null = `context.responsive` default
///  - [cursorNotifier] — when provided, subscribes to this notifier for the
///    cursor position instead of using a local Listener. Pass `null` and the
///    widget will use its own Listener (opaque hit testing). When provided,
///    wrap the field in `IgnorePointer` so pointer events still reach the
///    widgets in front.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.count = 100,
    this.opacity = 1.0,
    this.connectLines = true,
    this.reactRadius = 100.0,
    this.height,
    this.cursorNotifier,
  });

  final int count;
  final double opacity;
  final bool connectLines;
  final double reactRadius;
  final double? height;
  final ValueNotifier<Offset>? cursorNotifier;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  Ticker? _ticker;
  Offset _pointer = const Offset(-9999, -9999);
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  final _rng = Random();

  final _boxKey = GlobalKey();

  static final _colors = [
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
    widget.cursorNotifier?.addListener(_onCursor);
  }

  @override
  void didUpdateWidget(ParticleField old) {
    super.didUpdateWidget(old);
    if (old.cursorNotifier != widget.cursorNotifier) {
      old.cursorNotifier?.removeListener(_onCursor);
      widget.cursorNotifier?.addListener(_onCursor);
    }
  }

  void _onCursor() {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && widget.cursorNotifier != null) {
      _pointer = box.globalToLocal(widget.cursorNotifier!.value);
    }
  }

  void _spawn(Size size) {
    if (_particles.length >= widget.count) return;
    while (_particles.length < widget.count) {
      _particles.add(_Particle(
        pos: Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        vel: Offset((_rng.nextDouble() - 0.5) * 30, (_rng.nextDouble() - 0.5) * 30),
        color: _colors[_rng.nextInt(_colors.length)],
        r: 1.5 + _rng.nextDouble() * 2,
      ));
    }
  }

  void _tick(Duration elapsed) {
    if (_size == Size.zero) return;
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;

    for (final p in _particles) {
      final d = _pointer - p.pos;
      final dist = d.distance;
      if (dist < widget.reactRadius && dist > 1) {
        final force = (1 - dist / widget.reactRadius) * 180;
        p.vel -= d / dist * force * dt;
      }
      p.vel = p.vel * (pow(0.985, dt * 60) as double);
      p.pos += p.vel * dt;
      // Wrap
      if (p.pos.dx < 0) p.pos = Offset(_size.width, p.pos.dy);
      if (p.pos.dx > _size.width) p.pos = Offset(0, p.pos.dy);
      if (p.pos.dy < 0) p.pos = Offset(p.pos.dx, _size.height);
      if (p.pos.dy > _size.height) p.pos = Offset(p.pos.dx, 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.cursorNotifier?.removeListener(_onCursor);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ??
        context.responsive<double>(mobile: 260, desktop: 360);

    Widget content = LayoutBuilder(
      builder: (ctx, constraints) {
        _size = constraints.biggest;
        _spawn(_size);
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            linkDist: 80,
            connectLines: widget.connectLines,
            opacity: widget.opacity,
            reduceMotion: context.reduceMotion,
          ),
        );
      },
    );

    // If a cursorNotifier is provided, pointer events come from outside;
    // don't add a local Listener so we don't intercept events.
    if (widget.cursorNotifier == null) {
      content = MouseRegion(
        onExit: (_) => setState(() => _pointer = const Offset(-9999, -9999)),
        child: Listener(
          key: _boxKey,
          behavior: HitTestBehavior.opaque,
          onPointerHover: (e) => setState(() => _pointer = e.localPosition),
          onPointerMove: (e) => setState(() => _pointer = e.localPosition),
          child: content,
        ),
      );
    } else {
      content = SizedBox.expand(key: _boxKey, child: content);
    }

    return SizedBox(
      height: h,
      width: double.infinity,
      child: RepaintBoundary(child: content),
    );
  }
}

class _Particle {
  _Particle({required this.pos, required this.vel, required this.color, required this.r});
  Offset pos;
  Offset vel;
  final Color color;
  final double r;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.linkDist,
    required this.connectLines,
    required this.opacity,
    required this.reduceMotion,
  });

  final List<_Particle> particles;
  final double linkDist;
  final bool connectLines;
  final double opacity;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (connectLines && !reduceMotion) {
      for (var i = 0; i < particles.length; i++) {
        for (var j = i + 1; j < particles.length; j++) {
          final d = (particles[i].pos - particles[j].pos).distance;
          if (d < linkDist) {
            final alpha = (1 - d / linkDist) * 0.25 * opacity;
            canvas.drawLine(
              particles[i].pos,
              particles[j].pos,
              Paint()
                ..color = AppColors.textTertiary.withValues(alpha: alpha)
                ..strokeWidth = 0.8,
            );
          }
        }
      }
    }

    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.r,
        Paint()..color = p.color.withValues(alpha: 0.7 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => !reduceMotion;
}
