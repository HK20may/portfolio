import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'monte_carlo_engine.dart';

Future<MonteCarloResult> _compute(MonteCarloParams p) async {
  if (kIsWeb) return runMonteCarlo(p);
  return Isolate.run(() => runMonteCarlo(p));
}

class MonteCarloSim extends StatefulWidget {
  const MonteCarloSim({super.key});

  @override
  State<MonteCarloSim> createState() => _MonteCarloSimState();
}

class _MonteCarloSimState extends State<MonteCarloSim>
    with SingleTickerProviderStateMixin {
  double _mu = 0.08;
  double _sigma = 0.20;
  double _days = 252;
  double _sims = 200;

  MonteCarloResult? _result;
  bool _computing = false;
  Timer? _debounce;

  late final AnimationController _drawCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _scheduleCompute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _drawCtrl.value = 1;
  }

  void _scheduleCompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _run);
  }

  Future<void> _run() async {
    if (!mounted) return;
    setState(() => _computing = true);
    final p = MonteCarloParams(
      s0: 100,
      muAnnual: _mu,
      sigmaAnnual: _sigma,
      days: _days.round(),
      sims: _sims.round(),
      pathsToReturn: 60,
    );
    final result = await _compute(p);
    if (!mounted) return;
    setState(() {
      _result = result;
      _computing = false;
    });
    if (!context.reduceMotion) {
      _drawCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _drawCtrl.dispose();
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
                    size: 12, color: AppColors.textTertiary, spacing: 0.5)),
            Text(display,
                style: AppText.mono(
                    size: 12, color: AppColors.mint, spacing: 0)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.mint,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.mint,
            overlayColor: AppColors.mint.withValues(alpha: 0.2),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              setState(() => onChanged(v));
              _scheduleCompute();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final r = _result;

    final caption = kIsWeb
        ? 'Geometric Brownian Motion · ${_sims.round()} simulations computed off the render path'
        : 'Geometric Brownian Motion · ${_sims.round()} simulations computed in a background isolate — the UI never drops a frame.';

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slider(
          label: 'Drift μ (annual)',
          value: _mu,
          min: -0.20,
          max: 0.40,
          display: '${(_mu * 100).toStringAsFixed(0)}%',
          onChanged: (v) => _mu = v,
        ),
        _slider(
          label: 'Volatility σ (annual)',
          value: _sigma,
          min: 0.05,
          max: 0.80,
          display: '${(_sigma * 100).toStringAsFixed(0)}%',
          onChanged: (v) => _sigma = v,
        ),
        _slider(
          label: 'Horizon (days)',
          value: _days,
          min: 30,
          max: 252,
          display: '${_days.round()}d',
          onChanged: (v) => _days = v,
        ),
        _slider(
          label: 'Simulations',
          value: _sims,
          min: 50,
          max: 500,
          display: '${_sims.round()}',
          onChanged: (v) => _sims = v,
        ),
      ],
    );

    final chart = AnimatedBuilder(
      animation: _drawCtrl,
      builder: (context, _) {
        return Column(
          children: [
            SizedBox(
              height: 220,
              child: r == null
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.mint, strokeWidth: 1.5))
                  : CustomPaint(
                      painter: _PathPainter(
                        result: r,
                        progress: _drawCtrl.value,
                        accent: AppColors.mint,
                        s0: 100,
                      ),
                      size: const Size(double.infinity, 220),
                    ),
            ),
            if (r != null) ...[
              const SizedBox(height: Insets.md),
              SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _HistPainter(result: r, accent: AppColors.mint),
                  size: const Size(double.infinity, 80),
                ),
              ),
              const SizedBox(height: Insets.md),
              _StatsStrip(result: r),
            ],
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_computing)
          const Padding(
            padding: EdgeInsets.only(bottom: Insets.sm),
            child: LinearProgressIndicator(
              color: AppColors.mint,
              backgroundColor: AppColors.border,
              minHeight: 1.5,
            ),
          ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: controls),
              const SizedBox(width: Insets.xl),
              Expanded(child: chart),
            ],
          )
        else ...[
          controls,
          const SizedBox(height: Insets.lg),
          chart,
        ],
        const SizedBox(height: Insets.md),
        Text(caption,
            style: AppText.mono(
                size: 11, color: AppColors.textTertiary, spacing: 0.3)),
      ],
    );
  }
}

// ── Painters ────────────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.result,
    required this.progress,
    required this.accent,
    required this.s0,
  });
  final MonteCarloResult result;
  final double progress;
  final Color accent;
  final double s0;

  @override
  void paint(Canvas canvas, Size size) {
    if (result.samplePaths.isEmpty) return;

    final allVals = result.samplePaths.expand((p) => p).toList()
      ..addAll(result.meanPath);
    final minV = allVals.reduce(min) * 0.92;
    final maxV = allVals.reduce(max) * 1.08;
    final steps = result.meanPath.length;

    double px(int t) => t / (steps - 1) * size.width;
    double py(double v) => size.height - (v - minV) / (maxV - minV) * size.height;

    final cutoff = (progress * (steps - 1)).round();

    // Sample paths
    final faintPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final path in result.samplePaths) {
      final p = Path()..moveTo(px(0), py(path[0]));
      for (var t = 1; t <= cutoff && t < path.length; t++) {
        p.lineTo(px(t), py(path[t]));
      }
      canvas.drawPath(p, faintPaint);
    }

    // P5/P95 band (static, from meanPath proxy)
    // Mean path
    final meanPaint = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final mean = Path()..moveTo(px(0), py(result.meanPath[0]));
    for (var t = 1; t <= cutoff && t < result.meanPath.length; t++) {
      mean.lineTo(px(t), py(result.meanPath[t]));
    }
    canvas.drawPath(mean, meanPaint);

    // S0 baseline
    final base = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, py(s0)), Offset(size.width, py(s0)), base);
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.progress != progress || old.result != result;
}

class _HistPainter extends CustomPainter {
  _HistPainter({required this.result, required this.accent});
  final MonteCarloResult result;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const buckets = 30;
    final prices = result.finalPrices;
    final minV = prices.reduce(min);
    final maxV = prices.reduce(max);
    if (maxV == minV) return;
    final range = maxV - minV;
    final counts = List<int>.filled(buckets, 0);
    for (final p in prices) {
      final idx = ((p - minV) / range * (buckets - 1)).round().clamp(0, buckets - 1);
      counts[idx]++;
    }
    final maxC = counts.reduce(max).toDouble();
    final bw = size.width / buckets;
    for (var i = 0; i < buckets; i++) {
      final h = counts[i] / maxC * size.height;
      final r = Rect.fromLTWH(i * bw + 1, size.height - h, bw - 2, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()..color = accent.withValues(alpha: 0.5 + 0.4 * (counts[i] / maxC)),
      );
    }
  }

  @override
  bool shouldRepaint(_HistPainter old) => old.result != result;
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result});
  final MonteCarloResult result;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppText.display(
                size: 18, weight: FontWeight.w700, color: AppColors.mint)),
        Text(label,
            style: AppText.mono(
                size: 10, color: AppColors.textTertiary, spacing: 0.5)),
      ],
    );

    return Wrap(
      spacing: Insets.xl,
      runSpacing: Insets.md,
      children: [
        stat('Mean', '\$${result.mean.toStringAsFixed(1)}'),
        stat('Median', '\$${result.median.toStringAsFixed(1)}'),
        stat('P5', '\$${result.p5.toStringAsFixed(1)}'),
        stat('P95', '\$${result.p95.toStringAsFixed(1)}'),
        stat('Prob. Profit', '${(result.probProfit * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
}
