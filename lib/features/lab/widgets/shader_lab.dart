import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class ShaderLab extends StatefulWidget {
  const ShaderLab({super.key});

  @override
  State<ShaderLab> createState() => _ShaderLabState();
}

class _ShaderLabState extends State<ShaderLab>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  bool _failed = false;

  final ValueNotifier<Duration> _time = ValueNotifier(Duration.zero);
  Ticker? _ticker;

  double _speed = 1.0;
  double _warp = 1.0;
  double _glow = 0.22;
  double _hue = 0.0;

  Offset _mouse = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final prog = await ui.FragmentProgram.fromAsset('shaders/aurora_lab.frag');
      if (!mounted) return;
      setState(() => _shader = prog.fragmentShader());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick(Duration elapsed) {
    if (!context.reduceMotion) _time.value = elapsed;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppText.mono(
                    size: 11, color: AppColors.textTertiary, spacing: 0.5)),
            Text(display,
                style: AppText.mono(
                    size: 11, color: AppColors.violet, spacing: 0)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.violet,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.violet,
            overlayColor: AppColors.violet.withValues(alpha: 0.2),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              setState(() => onChanged(v));
              // Force time update so static image refreshes under reduceMotion
              if (context.reduceMotion) setState(() {});
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasH = context.responsive<double>(mobile: 180, desktop: 240);

    final canvas = SizedBox(
      height: canvasH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Corners.md),
        child: Listener(
          onPointerHover: (e) => setState(() => _mouse = e.localPosition),
          onPointerMove: (e) => setState(() => _mouse = e.localPosition),
          child: _failed || _shader == null
              ? RepaintBoundary(
                  child: CustomPaint(
                    painter: _LabFallbackPainter(time: _time),
                    size: Size.infinite,
                  ),
                )
              : RepaintBoundary(
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: _time,
                    builder: (context, t, _) => CustomPaint(
                      isComplex: true,
                      willChange: !context.reduceMotion,
                      painter: _LabShaderPainter(
                        shader: _shader!,
                        time: t,
                        mouse: _mouse,
                        speed: _speed,
                        warp: _warp,
                        glow: _glow,
                        hue: _hue,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
        ),
      ),
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slider(
          label: 'Speed',
          value: _speed,
          min: 0.1,
          max: 4.0,
          display: _speed.toStringAsFixed(1),
          onChanged: (v) => _speed = v,
        ),
        _slider(
          label: 'Detail (warp)',
          value: _warp,
          min: 0.3,
          max: 2.5,
          display: _warp.toStringAsFixed(1),
          onChanged: (v) => _warp = v,
        ),
        _slider(
          label: 'Glow',
          value: _glow,
          min: 0.0,
          max: 0.6,
          display: _glow.toStringAsFixed(2),
          onChanged: (v) => _glow = v,
        ),
        _slider(
          label: 'Hue shift',
          value: _hue,
          min: -3.14,
          max: 3.14,
          display: '${(_hue * 180 / 3.14159).toStringAsFixed(0)}°',
          onChanged: (v) => _hue = v,
        ),
      ],
    );

    return context.isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: canvas),
              const SizedBox(width: Insets.xl),
              SizedBox(width: 200, child: controls),
            ],
          )
        : Column(children: [canvas, const SizedBox(height: Insets.lg), controls]);
  }
}

class _LabShaderPainter extends CustomPainter {
  _LabShaderPainter({
    required this.shader,
    required this.time,
    required this.mouse,
    required this.speed,
    required this.warp,
    required this.glow,
    required this.hue,
  });

  final ui.FragmentShader shader;
  final Duration time;
  final Offset mouse;
  final double speed, warp, glow, hue;

  @override
  void paint(Canvas canvas, Size size) {
    final secs = time.inMicroseconds / 1e6;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, secs)
      ..setFloat(3, mouse.dx)
      ..setFloat(4, mouse.dy)
      ..setFloat(5, speed)
      ..setFloat(6, warp)
      ..setFloat(7, glow)
      ..setFloat(8, hue);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LabShaderPainter old) =>
      old.time != time || old.mouse != mouse ||
      old.speed != speed || old.warp != warp ||
      old.glow != glow || old.hue != hue;
}

/// Simple CPU gradient fallback shown when the lab shader fails to load.
class _LabFallbackPainter extends CustomPainter {
  _LabFallbackPainter({required this.time}) : super(repaint: time);
  final ValueNotifier<Duration> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value.inMicroseconds / 1e6;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            AppColors.violet.withValues(alpha: 0.6),
            AppColors.cyan.withValues(alpha: 0.4),
            AppColors.pink.withValues(alpha: 0.5),
          ],
          [
            0.0,
            0.5 + 0.2 * math.sin(t * 0.3),
            1.0,
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(_LabFallbackPainter old) => false;
}
