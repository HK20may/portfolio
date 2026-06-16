import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/responsive/responsive.dart';
import '../cursor/cursor_scope.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

class _PConf {
  const _PConf(
      {required this.angle, required this.speed, required this.colorIdx});
  final double angle, speed;
  final int colorIdx;
}

enum _Phase { idle, hopping, falling, underground, rising }

// ── Public widget ─────────────────────────────────────────────────────────────

/// Bird mascot using assets/images/mascot.png (1920×1080, indexed PNG with
/// tRNS transparency).
///
/// Interactions:
///  • Odd taps  → greeting hop + sparkles + "hi! 👋"
///  • Even taps → pre-fall hop up → shrink into hole → underground →
///                tap (or 5 s) → grow out of hole with bounce landing
///  • Cursor    → whole bird gently leans toward the pointer
class BirdMascot extends StatefulWidget {
  const BirdMascot({super.key});

  @override
  State<BirdMascot> createState() => _BirdMascotState();
}

class _BirdMascotState extends State<BirdMascot> with TickerProviderStateMixin {
  late final AnimationController _bobCtrl;
  late final AnimationController _hopCtrl;
  late final AnimationController _fallCtrl;
  late final AnimationController _riseCtrl;

  _Phase _phase = _Phase.idle;
  List<_PConf> _particles = const [];
  bool _showHi = false;
  bool _showHelp = false;
  bool _tapped = false;
  int _tapCount = 0;

  Completer<void>? _rescueCompleter;
  Timer? _autoRescueTimer;

  final _rng = Random();
  final _rootKey = GlobalKey();
  static final _zero = ValueNotifier<Offset>(Offset.zero);

  // ── Image geometry ──────────────────────────────────────────────────────────
  static const _imgW = 1920.0;
  static const _imgH = 1080.0;
  static const _footYFrac = 0.92; // bird feet as fraction of image height

  // Portion of the fall controller used for the pre-fall hop (0→1 range).
  static const _hopPortion = 0.25;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _hopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fallCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _riseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _hopCtrl.addStatusListener(_onHopDone);
  }

  void _onHopDone(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted)
          setState(() {
            _particles = const [];
            _showHi = false;
            _phase = _Phase.idle;
          });
      });
    }
  }

  // ── Tap handler ──────────────────────────────────────────────────────────────

  void _handleTap() {
    if (!mounted) return;
    if (_phase == _Phase.underground) {
      _rescueNow();
      return;
    }
    if (_phase != _Phase.idle) return;
    _tapCount++;
    _tapped = true;
    _tapCount.isOdd ? _doGreeting() : _doFall();
  }

  void _rescueNow() {
    _autoRescueTimer?.cancel();
    final c = _rescueCompleter;
    if (c != null && !c.isCompleted) c.complete();
  }

  // ── Greeting ─────────────────────────────────────────────────────────────────

  void _doGreeting() {
    HapticFeedback.mediumImpact();
    final reduce = context.reduceMotion;
    final count = reduce ? 0 : 8;
    setState(() {
      _phase = _Phase.hopping;
      _showHi = true;
      _particles = List.generate(count, (i) {
        final frac = i / count;
        return _PConf(
          angle: -pi * 0.15 - frac * pi * 1.7,
          speed: 0.55 + _rng.nextDouble() * 0.55,
          colorIdx: i % 3,
        );
      });
    });
    _hopCtrl.forward(from: 0);
  }

  // ── Fall sequence ─────────────────────────────────────────────────────────────
  // Timeline (normalised _fallCtrl 0→1 over 1.4 s):
  //   0.00→0.25 : pre-fall hop up  (bird jumps, scale stays 1)
  //   0.25→1.00 : fall + shrink    (easeIn; scale 1→0)

  Future<void> _doFall() async {
    HapticFeedback.heavyImpact();
    _bobCtrl.stop();
    setState(() {
      _phase = _Phase.falling;
    });

    await _fallCtrl.animateTo(1,
        curve: Curves.linear, duration: const Duration(milliseconds: 1400));
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.underground;
      _showHelp = true;
    });

    _rescueCompleter = Completer<void>();
    _autoRescueTimer = Timer(const Duration(seconds: 5), _rescueNow);
    await _rescueCompleter!.future;
    _rescueCompleter = null;
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _showHelp = false;
      _phase = _Phase.rising;
    });

    await _riseCtrl.animateTo(1,
        curve: Curves.linear, duration: const Duration(milliseconds: 1100));
    if (!mounted) return;

    _fallCtrl.reset();
    _riseCtrl.reset();
    if (!context.reduceMotion) _bobCtrl.repeat(reverse: true);
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.idle;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _bobCtrl.stop();
  }

  @override
  void dispose() {
    _autoRescueTimer?.cancel();
    final c = _rescueCompleter;
    if (c != null && !c.isCompleted) c.complete();
    _bobCtrl.dispose();
    _hopCtrl.dispose();
    _fallCtrl.dispose();
    _riseCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cursor = CursorScope.maybeOf(context);
    final cursorNotifier = cursor?.position ?? _zero;
    final reduce = context.reduceMotion;

    return GestureDetector(
      key: _rootKey,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Scale so image is 1.85× phone width; bird (image x ≈ 550–1370)
          // lands at display x ≈ 28–175, fully inside a ~210px phone.
          final imgScale = w * 1.85 / _imgW;
          final displayW = _imgW * imgScale;
          final displayH = _imgH * imgScale;
          final imgOffY = (h - displayH) / 2;

          // Bird feet in local display coords (rest position, hole stays here).
          final holeCenter = Offset(w / 2, imgOffY + _footYFrac * displayH);

          // Fall distance: enough to sink bird fully into the hole.
          final fallDist = h * 0.42;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Dark background ──
              const RepaintBoundary(child: CustomPaint(painter: _BgPainter())),

              // ── Hole (visible during fall sequence) ──
              if (_phase == _Phase.falling ||
                  _phase == _Phase.underground ||
                  _phase == _Phase.rising)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_fallCtrl, _riseCtrl]),
                    builder: (_, __) {
                      final double holeT;
                      if (_phase == _Phase.falling) {
                        // Hole starts growing after the pre-fall hop
                        final t = _fallCtrl.value;
                        holeT = t <= _hopPortion
                            ? 0.0
                            : Curves.easeOut.transform(
                                (t - _hopPortion) / (1 - _hopPortion));
                      } else if (_phase == _Phase.underground) {
                        holeT = 1.0;
                      } else {
                        // Hole closes as bird rises
                        holeT = (1.0 - Curves.easeIn.transform(_riseCtrl.value))
                            .clamp(0.0, 1.0);
                      }
                      return CustomPaint(
                        painter: _HolePainter(
                            center: holeCenter, t: holeT, canvasW: w),
                      );
                    },
                  ),
                ),

              // ── Bird image + cursor lean — combined AnimatedBuilder ──
              AnimatedBuilder(
                animation: Listenable.merge([
                  _bobCtrl,
                  _hopCtrl,
                  _fallCtrl,
                  _riseCtrl,
                  cursorNotifier,
                ]),
                builder: (_, __) {
                  // ── Vertical offset + scale based on phase ──
                  double dy, birdScale;
                  switch (_phase) {
                    case _Phase.falling:
                      final t = _fallCtrl.value;
                      if (t <= _hopPortion) {
                        // Pre-fall hop up
                        final pt = t / _hopPortion;
                        dy = -sin(pt * pi) * h * 0.09;
                        birdScale = 1.0;
                      } else {
                        // Shrink + fall
                        final ft = Curves.easeIn
                            .transform((t - _hopPortion) / (1 - _hopPortion));
                        dy = ft * fallDist;
                        birdScale = (1.0 - ft).clamp(0.0, 1.0);
                      }
                    case _Phase.underground:
                      dy = fallDist;
                      birdScale = 0.0;
                    case _Phase.rising:
                      // Grow while rising; bounceOut gives landing bounce.
                      final posT = Curves.bounceOut.transform(_riseCtrl.value);
                      final scaleT = Curves.easeOut.transform(_riseCtrl.value);
                      dy = (1.0 - posT) * fallDist;
                      birdScale = scaleT.clamp(0.0, 1.0);
                    case _Phase.hopping:
                      dy = -sin(_hopCtrl.value * pi) * h * 0.09;
                      birdScale = 1.0;
                    default:
                      dy = reduce ? 0 : sin(_bobCtrl.value * pi) * 5;
                      birdScale = 1.0;
                  }

                  // ── Cursor lean (whole-bird, no eye alignment needed) ──
                  Offset lean = Offset.zero;
                  if (cursor != null) {
                    final cursorPos = cursorNotifier.value;
                    if (cursorPos != Offset.zero) {
                      final box = _rootKey.currentContext?.findRenderObject()
                          as RenderBox?;
                      if (box != null && box.hasSize) {
                        final local = box.globalToLocal(cursorPos);
                        lean = Offset(
                          (local.dx / box.size.width - 0.5) * 7.0,
                          (local.dy / box.size.height - 0.5) * 3.5,
                        );
                      }
                    }
                  }

                  return Transform.translate(
                    offset: Offset(lean.dx, dy + lean.dy),
                    child: Transform.scale(
                      scale: birdScale.clamp(0.0, 1.0),
                      // OverflowBox: minWidth/minHeight must be 0 so that
                      // maxWidth/maxHeight can be SMALLER than the parent's
                      // tight constraints without producing invalid constraints.
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: displayW,
                        minHeight: 0,
                        maxHeight: displayH,
                        child: Image.asset(
                          'assets/images/mascot.png',
                          width: displayW,
                          height: displayH,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Sparkle particles ──
              if (_particles.isNotEmpty)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _hopCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ParticlePainter(
                        hop: _hopCtrl.value,
                        particles: _particles,
                        origin: Offset(w / 2, h * 0.33),
                        canvasW: w,
                      ),
                    ),
                  ),
                ),

              // ── "hi! 👋" bubble ──
              if (_showHi)
                Align(
                  alignment: const Alignment(0.50, -0.28),
                  child: IgnorePointer(
                    child: _SpeechBubble(
                      key: ValueKey('hi$_tapCount'),
                      text: 'hi! 👋',
                    ),
                  ),
                ),

              // ── Rescue prompt ──
              if (_showHelp)
                Align(
                  alignment: const Alignment(0, 0.28),
                  child: _RescueBubble(key: ValueKey('rescue$_tapCount')),
                ),

              // ── First-visit hint ──
              if (!_tapped)
                const Align(
                  alignment: Alignment(0, 0.92),
                  child: _TapHint(),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  const _BgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [Color(0xFF0E1830), Color(0xFF07070E)],
        ).createShader(rect),
    );
    _blob(canvas, Offset(size.width * 0.15, size.height * 0.15), 44,
        const Color(0xFF7C5CFF), 0.09);
    _blob(canvas, Offset(size.width * 0.85, size.height * 0.20), 33,
        const Color(0xFF2DD4FF), 0.07);
    _blob(canvas, Offset(size.width * 0.50, size.height * 0.86), 25,
        const Color(0xFF49E6A6), 0.06);
  }

  void _blob(Canvas canvas, Offset c, double r, Color col, double a) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = col.withValues(alpha: a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }

  @override
  bool shouldRepaint(_BgPainter _) => false;
}

// ── Hole ──────────────────────────────────────────────────────────────────────

class _HolePainter extends CustomPainter {
  const _HolePainter(
      {required this.center, required this.t, required this.canvasW});
  final Offset center;
  final double t; // 0 = no hole, 1 = full hole
  final double canvasW;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final rw = canvasW * 0.42 * t;
    final rh = rw * 0.30;

    // Outer violet glow (theme colour, visible on dark bg)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rw * 3.0, height: rh * 3.0),
      Paint()
        ..color = const Color(0xFF7C5CFF).withValues(alpha: 0.28 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // Warm-brown earth rim
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rw * 2.2, height: rh * 2.2),
      Paint()..color = const Color(0xFF5C3D1A),
    );
    // Dark inner ring
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rw * 2.0, height: rh * 2.0),
      Paint()..color = const Color(0xFF2A1A08),
    );
    // Near-black void
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rw * 1.7, height: rh * 1.7),
      Paint()..color = const Color(0xFF05040A),
    );
    // Top rim highlight
    canvas.drawArc(
      Rect.fromCenter(center: center, width: rw * 2.1, height: rh * 2.1),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFB87A3A).withValues(alpha: 0.60 * t)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.t != t;
}

// ── Particles ─────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.hop,
    required this.particles,
    required this.origin,
    required this.canvasW,
  });
  final double hop;
  final List<_PConf> particles;
  final Offset origin;
  final double canvasW;

  static const _colors = [
    Color(0xFFFF5C8A),
    Color(0xFF7C5CFF),
    Color(0xFF2DD4FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = hop.clamp(0.0, 1.0);
    for (final p in particles) {
      final dist = t * p.speed * canvasW * 0.50;
      final px = origin.dx + cos(p.angle) * dist;
      final py = origin.dy + sin(p.angle) * dist + t * t * 14;
      final opacity = (1.0 - t * 1.1).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final r = 5.0 + (1 - t) * 4;
      canvas.drawCircle(
          Offset(px, py),
          r,
          Paint()
            ..color = _colors[p.colorIdx].withValues(alpha: opacity * 0.9));
      final sp = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(px, py - r), Offset(px, py + r), sp);
      canvas.drawLine(Offset(px - r, py), Offset(px + r, py), sp);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.hop != hop || old.particles.length != particles.length;
}

// ── Rescue prompt ─────────────────────────────────────────────────────────────

class _RescueBubble extends StatefulWidget {
  const _RescueBubble({super.key});
  @override
  State<_RescueBubble> createState() => _RescueBubbleState();
}

class _RescueBubbleState extends State<_RescueBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350))
    ..forward();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1040),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7C5CFF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CFF).withValues(alpha: 0.38),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Text('tap to rescue! 🆘',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFFCCBBFF),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      ),
    );
  }
}

// ── "hi!" speech bubble ───────────────────────────────────────────────────────

class _SpeechBubble extends StatefulWidget {
  const _SpeechBubble({super.key, required this.text});
  final String text;
  @override
  State<_SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<_SpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300))
    ..forward();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(widget.text,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF12122A),
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── "tap me!" first-visit hint ────────────────────────────────────────────────

class _TapHint extends StatefulWidget {
  const _TapHint();
  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.30, end: 0.85)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: const Text('tap me!',
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF8888A0),
              letterSpacing: 2.5)),
    );
  }
}
