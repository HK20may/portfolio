import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/responsive/responsive.dart';
import '../../state/palette_cubit.dart';
import '../cursor/cursor_scope.dart';

/// Full-bleed ambient background. Tries to drive `shaders/aurora.frag`; if that
/// fails for any reason it falls back to a CPU-painted gradient.
///
/// The `uVivid` uniform (slot 5) is eased toward 0 (calm) or 1 (vivid) each
/// tick, driven by `PaletteCubit`.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> {
  ui.FragmentShader? _shader;
  bool _triedLoad = false;

  final ValueNotifier<Duration> _time = ValueNotifier(Duration.zero);
  final ValueNotifier<double> _vivid = ValueNotifier(0.0);
  double _vividTarget = 0.0;

  Ticker? _ticker;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/aurora.frag');
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _triedLoad = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Aurora shader unavailable, using fallback: $e');
      if (mounted) setState(() => _triedLoad = true);
    }
  }

  void _onTick(Duration elapsed) {
    if (_animate) _time.value = elapsed;
    // Ease vivid toward its target each tick.
    final next = _vivid.value + (_vividTarget - _vivid.value) * 0.06;
    if ((next - _vivid.value).abs() > 0.001) _vivid.value = next;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !context.reduceMotion;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    _vivid.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update vivid target whenever the palette changes.
    return BlocBuilder<PaletteCubit, Palette>(
      builder: (context, palette) {
        _vividTarget = palette == Palette.vivid ? 1.0 : 0.0;

        final cursor = CursorScope.maybeOf(context);
        final mouse = cursor?.position ?? ValueNotifier<Offset>(Offset.zero);

        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: ValueListenableBuilder<Offset>(
                valueListenable: mouse,
                builder: (context, mousePos, _) {
                  return CustomPaint(
                    isComplex: true,
                    willChange: true,
                    size: Size.infinite,
                    painter: _shader != null
                        ? _ShaderPainter(
                            shader: _shader!,
                            time: _time,
                            vivid: _vivid,
                            mouse: mousePos,
                          )
                        : _FallbackAuroraPainter(time: _time, mouse: mousePos),
                  );
                },
              ),
            ),
            // Darkening scrim — aurora visible at center, darker at top/bottom.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xD905050B),
                      Color(0x8C05050B),
                      Color(0x5905050B),
                      Color(0x9905050B),
                      Color(0xE605050B),
                    ],
                    stops: [0.0, 0.18, 0.5, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({
    required this.shader,
    required this.time,
    required this.vivid,
    required this.mouse,
  }) : super(repaint: Listenable.merge([time, vivid]));

  final ui.FragmentShader shader;
  final ValueNotifier<Duration> time;
  final ValueNotifier<double> vivid;
  final Offset mouse;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = time.value.inMicroseconds / 1e6;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds)
      ..setFloat(3, mouse.dx)
      ..setFloat(4, mouse.dy)
      ..setFloat(5, vivid.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => old.mouse != mouse;
}

/// CPU fallback — three drifting radial glows.
class _FallbackAuroraPainter extends CustomPainter {
  _FallbackAuroraPainter({required this.time, required this.mouse})
      : super(repaint: time);

  final ValueNotifier<Duration> time;
  final Offset mouse;

  static const _base = Color(0xFF07070E);
  static const _violet = Color(0xFF7C5CFF);
  static const _cyan = Color(0xFF2DD4FF);
  static const _pink = Color(0xFFFF5C8A);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value.inMicroseconds / 1e6;
    canvas.drawRect(Offset.zero & size, Paint()..color = _base);

    void blob(Color color, Offset center, double radius) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(center, radius, [
            color.withOpacity(0.55),
            color.withOpacity(0.0),
          ]),
      );
    }

    final w = size.width, h = size.height;
    final r = size.shortestSide * 0.85;

    blob(_violet,
        Offset(w * (0.30 + 0.10 * _sin(t * 0.18)), h * (0.32 + 0.08 * _cos(t * 0.15))), r);
    blob(_cyan,
        Offset(w * (0.72 + 0.08 * _cos(t * 0.13)), h * (0.40 + 0.10 * _sin(t * 0.20))), r * 0.9);
    blob(_pink,
        Offset(w * (0.55 + 0.12 * _sin(t * 0.11 + 1.5)), h * (0.78 + 0.06 * _cos(t * 0.17))),
        r * 0.8);

    if (mouse != Offset.zero) blob(_cyan, mouse, size.shortestSide * 0.28);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          size.longestSide * 0.75,
          [const Color(0x00000000), const Color(0xCC000000)],
          [0.55, 1.0],
        ),
    );
  }

  double _sin(double x) => _approxSin(x);
  double _cos(double x) => _approxSin(x + 1.5707963);

  double _approxSin(double x) {
    const twoPi = 6.28318530718;
    x = x % twoPi;
    if (x < 0) x += twoPi;
    final xn = x > 3.14159265 ? x - 6.28318530718 : x;
    return 1.27323954 * xn - 0.405284735 * xn * xn.abs();
  }

  @override
  bool shouldRepaint(_FallbackAuroraPainter old) => old.mouse != mouse;
}
