import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'monte_carlo_engine.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class PricePoint {
  const PricePoint(this.date, this.close);
  final DateTime date;
  final double close;
}

class _TickerInfo {
  const _TickerInfo({
    required this.code,
    required this.label,
  });
  final String code;
  final String label; // display name shown in dropdown

  String get symbol => r'$'; // all tickers are USD-denominated
}

const _tickers = [
  // US equities
  _TickerInfo(code: 'AAPL', label: 'AAPL — Apple'),
  _TickerInfo(code: 'NVDA', label: 'NVDA — Nvidia'),
  _TickerInfo(code: 'TSLA', label: 'TSLA — Tesla'),
  _TickerInfo(code: 'MSFT', label: 'MSFT — Microsoft'),
  _TickerInfo(code: 'GOOGL', label: 'GOOGL — Alphabet'),
  _TickerInfo(code: 'META', label: 'META — Meta'),
  _TickerInfo(code: 'AMZN', label: 'AMZN — Amazon'),
  _TickerInfo(code: 'SPY', label: 'SPY — S&P 500 ETF'),
  // Crypto
  _TickerInfo(code: 'BTC/USD', label: 'BTC — Bitcoin'),
  _TickerInfo(code: 'ETH/USD', label: 'ETH — Ethereum'),
];

// ── API fetch ─────────────────────────────────────────────────────────────────

// Get a free key at https://twelvedata.com (800 req/day, CORS-enabled).
const String _twelveDataKey = '35d85f0025214b6d86538857900ea945';

Future<List<PricePoint>> fetchDailyCloses({
  required String symbol,
  int outputsize = 400,
}) async {
  final qp = {
    'symbol': symbol,
    'interval': '1day',
    'outputsize': '$outputsize',
    'order': 'ASC',
    'apikey': _twelveDataKey,
  };
  final uri = Uri.https('api.twelvedata.com', '/time_series', qp);
  debugPrint('[MonteCarlo] Fetching $symbol — URL: $uri');

  late http.Response res;
  try {
    res = await http.get(uri).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('[MonteCarlo] Network error for $symbol: $e');
    rethrow;
  }

  debugPrint('[MonteCarlo] HTTP ${res.statusCode} for $symbol');
  debugPrint('[MonteCarlo] Body (first 500 chars): ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');

  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode} for $symbol');
  }

  Map<String, dynamic> j;
  try {
    j = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('[MonteCarlo] JSON parse error for $symbol: $e');
    throw Exception('Invalid JSON response for $symbol');
  }

  if (j['status'] == 'error' || j['values'] == null) {
    final msg = j['message'] ?? j['code']?.toString() ?? 'price fetch failed';
    debugPrint('[MonteCarlo] API error for $symbol: $msg — full response keys: ${j.keys.toList()}');
    throw Exception('API error for $symbol: $msg');
  }

  final values = (j['values'] as List).cast<Map<String, dynamic>>();
  debugPrint('[MonteCarlo] Got ${values.length} candles for $symbol');
  return values
      .map((v) => PricePoint(
            DateTime.parse(v['datetime'] as String),
            double.parse(v['close'] as String),
          ))
      .toList();
}

// ── Calibration ───────────────────────────────────────────────────────────────

({double mu, double sigma, double s0}) calibrate(List<PricePoint> series) {
  final closes = series.map((p) => p.close).toList();
  final rets = <double>[];
  for (var i = 1; i < closes.length; i++) {
    rets.add(log(closes[i] / closes[i - 1]));
  }
  final mean = rets.reduce((a, b) => a + b) / rets.length;
  final variance =
      rets.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
          rets.length;
  final sd = sqrt(variance);
  return (mu: mean * 252, sigma: sd * sqrt(252), s0: closes.last);
}

// ── Compute helper ────────────────────────────────────────────────────────────

Future<MonteCarloResult> _compute(MonteCarloParams p) async {
  if (kIsWeb) return runMonteCarlo(p);
  return Isolate.run(() => runMonteCarlo(p));
}

// ── Mode ──────────────────────────────────────────────────────────────────────

enum _SimMode { real, custom }

// ── Widget ────────────────────────────────────────────────────────────────────

class MonteCarloSim extends StatefulWidget {
  const MonteCarloSim({super.key, this.compact = false});

  /// When true, reduces chart height for embedding in a detail-page demo block.
  final bool compact;

  @override
  State<MonteCarloSim> createState() => _MonteCarloSimState();
}

class _MonteCarloSimState extends State<MonteCarloSim>
    with SingleTickerProviderStateMixin {
  // Custom-mode params (also used for horizon/sims in real mode)
  double _mu = 0.08;
  double _sigma = 0.20;
  double _days = 126;
  double _sims = 300;

  // Real-mode state
  _SimMode _mode = _SimMode.real;
  _TickerInfo _ticker = _tickers.first;
  List<PricePoint>? _history;
  bool _fetchLoading = false;
  String? _fetchError;
  double? _impliedMu, _impliedSigma, _impliedS0;

  // Per-step cone paths (precomputed)
  List<double>? _coneP5, _coneP95;

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
    _fetchAndRun();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _drawCtrl.value = 1;
  }

  String _fmt(double v) {
    // Always use the selected ticker's symbol; default ticker is RELIANCE → ₹.
    return '${_ticker.symbol}${_fmtNum(v)}';
  }

  String _fmtNum(double v) {
    final s = v.toStringAsFixed(2);
    final dot = s.indexOf('.');
    final intPart = s.substring(0, dot);
    final decPart = s.substring(dot);
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${buf.toString()}$decPart';
  }

  // ── Data fetch ──────────────────────────────────────────────────────────────

  Future<void> _fetchAndRun() async {
    if (_mode == _SimMode.custom) {
      _scheduleCompute();
      return;
    }
    setState(() {
      _fetchLoading = true;
      _fetchError = null;
      _history = null;
      _result = null;
      _coneP5 = null;
      _coneP95 = null;
    });

    try {
      final data = await fetchDailyCloses(symbol: _ticker.code);
      if (!mounted) return;
      final cal = calibrate(data);
      setState(() {
        _history = data;
        _impliedMu = cal.mu;
        _impliedSigma = cal.sigma;
        _impliedS0 = cal.s0;
        _fetchLoading = false;
      });
      await _runWithParams(s0: cal.s0, mu: cal.mu, sigma: cal.sigma);
    } catch (e, st) {
      debugPrint('[MonteCarlo] _fetchAndRun error: $e');
      debugPrint('[MonteCarlo] Stack: $st');
      if (!mounted) return;
      setState(() {
        _fetchLoading = false;
        _fetchError = 'Could not load ${_ticker.label.split(' ').first}: $e';
        _mode = _SimMode.custom;
      });
      _scheduleCompute();
    }
  }

  // ── Compute ─────────────────────────────────────────────────────────────────

  void _scheduleCompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_mode == _SimMode.custom) {
        _runWithParams(s0: 100, mu: _mu, sigma: _sigma);
      } else if (_impliedS0 != null) {
        _runWithParams(s0: _impliedS0!, mu: _impliedMu!, sigma: _impliedSigma!);
      }
    });
  }

  Future<void> _runWithParams({
    required double s0,
    required double mu,
    required double sigma,
  }) async {
    if (!mounted) return;
    setState(() => _computing = true);
    final p = MonteCarloParams(
      s0: s0,
      muAnnual: mu,
      sigmaAnnual: sigma,
      days: _days.round(),
      sims: _sims.round(),
      pathsToReturn: 80,
    );
    final result = await _compute(p);
    if (!mounted) return;

    // Precompute per-step P5/P95 from sample paths for the cone
    final cone = _buildCone(result);

    setState(() {
      _result = result;
      _coneP5 = cone.$1;
      _coneP95 = cone.$2;
      _computing = false;
    });
    if (!context.reduceMotion) _drawCtrl.forward(from: 0);
  }

  (List<double>, List<double>) _buildCone(MonteCarloResult r) {
    final paths = r.samplePaths;
    if (paths.isEmpty) return (<double>[], <double>[]);
    final steps = paths[0].length;
    final p5 = List<double>.filled(steps, 0);
    final p95 = List<double>.filled(steps, 0);
    for (var t = 0; t < steps; t++) {
      final vals = paths.map((path) => path[t]).toList()..sort();
      p5[t] = vals[((0.05) * (vals.length - 1)).round()];
      p95[t] = vals[((0.95) * (vals.length - 1)).round()];
    }
    return (p5, p95);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _drawCtrl.dispose();
    super.dispose();
  }

  // ── Sliders ─────────────────────────────────────────────────────────────────

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
                style:
                    AppText.mono(size: 12, color: AppColors.mint, spacing: 0)),
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

  Widget _readonlyStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.mono(
                  size: 11, color: AppColors.textTertiary, spacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.mono(size: 13, color: AppColors.cyan, spacing: 0)),
        ],
      );

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final r = _result;

    // Display last 200 history points so the chart isn't too cramped
    final displayHistory = _history != null
        ? _history!
            .sublist(max(0, _history!.length - 200))
            .map((p) => p.close)
            .toList()
        : <double>[];

    // ── Mode toggle ─────────────────────────────────────────────────────────
    final modeToggle = Row(
      children: [
        _ModeChip(
          label: 'Real stock',
          active: _mode == _SimMode.real,
          onTap: () {
            if (_mode == _SimMode.real) return;
            setState(() {
              _mode = _SimMode.real;
              _fetchError = null;
            });
            _fetchAndRun();
          },
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Custom',
          active: _mode == _SimMode.custom,
          onTap: () {
            if (_mode == _SimMode.custom) return;
            setState(() {
              _mode = _SimMode.custom;
              _history = null;
              _result = null;
            });
            _scheduleCompute();
          },
        ),
      ],
    );

    // ── Controls ─────────────────────────────────────────────────────────────
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ticker dropdown (real mode only)
        if (_mode == _SimMode.real) ...[
          Text('Ticker',
              style: AppText.mono(
                  size: 11, color: AppColors.textTertiary, spacing: 0.5)),
          const SizedBox(height: 4),
          _TickerDropdown(
            tickers: _tickers,
            selected: _ticker,
            onChanged: (t) {
              setState(() {
                _ticker = t;
                _history = null;
                _result = null;
              });
              _fetchAndRun();
            },
          ),
          const SizedBox(height: Insets.md),
          // Implied stats
          if (_impliedMu != null && _impliedSigma != null) ...[
            Row(
              children: [
                Expanded(
                  child: _readonlyStat(
                    'Implied drift (μ)',
                    '${(_impliedMu! * 100).toStringAsFixed(1)}% p.a.',
                  ),
                ),
                Expanded(
                  child: _readonlyStat(
                    'Implied vol (σ)',
                    '${(_impliedSigma! * 100).toStringAsFixed(1)}% p.a.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
          ],
        ],
        // Custom mode μ/σ sliders
        if (_mode == _SimMode.custom) ...[
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
        ],
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

    // ── Chart ────────────────────────────────────────────────────────────────
    final chart = AnimatedBuilder(
      animation: _drawCtrl,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: widget.compact ? 160 : 220,
              child: _fetchLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.mint, strokeWidth: 1.5))
                  : r == null && !_fetchLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.mint, strokeWidth: 1.5))
                      : r != null
                          ? RepaintBoundary(
                              child: CustomPaint(
                                painter: _CombinedPainter(
                                  history: displayHistory,
                                  result: r,
                                  progress: _drawCtrl.value,
                                  accent: AppColors.mint,
                                  coneP5: _coneP5 ?? [],
                                  coneP95: _coneP95 ?? [],
                                ),
                                size: const Size(double.infinity, 220),
                              ),
                            )
                          : const SizedBox(),
            ),
            if (r != null) ...[
              const SizedBox(height: Insets.md),
              SizedBox(
                height: 70,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _HistPainter(result: r, accent: AppColors.mint),
                    size: const Size(double.infinity, 70),
                  ),
                ),
              ),
              const SizedBox(height: Insets.md),
              _StatsStrip(result: r, fmt: _fmt),
            ],
          ],
        );
      },
    );

    // ── Caption ──────────────────────────────────────────────────────────────
    final tickerShort = _ticker.code.contains('/') ? _ticker.code.split('/')[0] : _ticker.code;
    final caption = _mode == _SimMode.real && _history != null
        ? 'Calibrated on ${_history!.length} days of real $tickerShort prices'
            ' · forward paths computed in a background isolate'
        : kIsWeb
            ? 'Geometric Brownian Motion · ${_sims.round()} simulations'
            : 'Geometric Brownian Motion · ${_sims.round()} simulations'
                ' computed in a background isolate — the UI never drops a frame.';

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        modeToggle,
        const SizedBox(height: Insets.md),
        if (_fetchError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: Text(
              _fetchError!,
              style: AppText.mono(
                  size: 11,
                  color: AppColors.amber.withValues(alpha: 0.9),
                  spacing: 0),
            ),
          ),
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
              SizedBox(width: 240, child: controls),
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

    // compact = true means the widget is inside the project-detail demo box,
    // which has a fixed maxHeight. Wrap in SingleChildScrollView so the full
    // controls + chart are reachable without overflowing.
    // compact = false (lab page) = no height cap, plain column is fine.
    if (widget.compact) {
      return SingleChildScrollView(child: column);
    }
    return column;
  }
}

// ── Mode chip ─────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.mint.withValues(alpha: 0.18)
              : AppColors.glassHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.mint.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppText.mono(
            size: 12,
            color: active ? AppColors.mint : AppColors.textSecondary,
            spacing: 0,
          ),
        ),
      ),
    );
  }
}

// ── Ticker dropdown ───────────────────────────────────────────────────────────

class _TickerDropdown extends StatelessWidget {
  const _TickerDropdown({
    required this.tickers,
    required this.selected,
    required this.onChanged,
  });
  final List<_TickerInfo> tickers;
  final _TickerInfo selected;
  final ValueChanged<_TickerInfo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<_TickerInfo>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF0E0E18),
        icon: const Icon(Icons.expand_more_rounded,
            size: 18, color: AppColors.textTertiary),
        style: AppText.mono(size: 13, color: AppColors.textPrimary, spacing: 0),
        items: tickers
            .map((t) => DropdownMenuItem<_TickerInfo>(
                  value: t,
                  child: Text(
                    t.label,
                    style: AppText.mono(
                        size: 13, color: AppColors.textPrimary, spacing: 0),
                  ),
                ))
            .toList(),
        onChanged: (t) {
          if (t != null) onChanged(t);
        },
      ),
    );
  }
}

// ── Combined painter (history + forward) ─────────────────────────────────────

class _CombinedPainter extends CustomPainter {
  _CombinedPainter({
    required this.history,
    required this.result,
    required this.progress,
    required this.accent,
    required this.coneP5,
    required this.coneP95,
  });
  final List<double> history;
  final MonteCarloResult result;
  final double progress;
  final Color accent;
  final List<double> coneP5;
  final List<double> coneP95;

  @override
  void paint(Canvas canvas, Size size) {
    final histN = history.length;
    final fwdN = result.meanPath.length;
    if (histN == 0 && fwdN == 0) return;

    final totalN = histN + fwdN - 1;
    if (totalN <= 1) return;

    // Overall value range
    var minV =
        history.isNotEmpty ? history.reduce(min) : result.meanPath.reduce(min);
    var maxV =
        history.isNotEmpty ? history.reduce(max) : result.meanPath.reduce(max);
    for (final path in result.samplePaths) {
      for (final v in path) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    minV *= 0.93;
    maxV *= 1.07;
    final range = maxV - minV;
    if (range == 0) return;

    double px(int t) => t / (totalN - 1) * size.width;
    double py(double v) => size.height - (v - minV) / range * size.height;

    final cutoffX = histN > 0 ? px(histN - 1) : 0.0;
    final cutoff = ((progress) * (fwdN - 1)).round().clamp(0, fwdN - 1);

    // P5–P95 cone
    if (coneP5.isNotEmpty && coneP95.isNotEmpty) {
      final conePath = Path();
      bool started = false;
      for (var t = 0; t <= cutoff && t < coneP95.length; t++) {
        final x = px(histN - 1 + t);
        final y = py(coneP95[t]);
        if (!started) {
          conePath.moveTo(x, y);
          started = true;
        } else {
          conePath.lineTo(x, y);
        }
      }
      for (var t = min(cutoff, coneP5.length - 1); t >= 0; t--) {
        conePath.lineTo(px(histN - 1 + t), py(coneP5[t]));
      }
      if (started) {
        conePath.close();
        canvas.drawPath(
          conePath,
          Paint()..color = accent.withValues(alpha: 0.13),
        );
      }
    }

    // Sample paths (faint forward)
    final samplePaint = Paint()
      ..color = accent.withValues(alpha: 0.09)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final path in result.samplePaths) {
      final p = Path()..moveTo(cutoffX, py(path[0]));
      for (var t = 1; t <= cutoff && t < path.length; t++) {
        p.lineTo(px(histN - 1 + t), py(path[t]));
      }
      canvas.drawPath(p, samplePaint);
    }

    // Mean forward path
    if (fwdN > 0) {
      final meanPaint = Paint()
        ..color = accent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final mean = Path()..moveTo(cutoffX, py(result.meanPath[0]));
      for (var t = 1; t <= cutoff && t < result.meanPath.length; t++) {
        mean.lineTo(px(histN - 1 + t), py(result.meanPath[t]));
      }
      canvas.drawPath(mean, meanPaint);
    }

    // History line
    if (histN > 0) {
      final histPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final hist = Path()..moveTo(px(0), py(history[0]));
      for (var i = 1; i < histN; i++) {
        hist.lineTo(px(i), py(history[i]));
      }
      canvas.drawPath(hist, histPaint);
    }

    // Cutoff divider
    if (histN > 0) {
      canvas.drawLine(
        Offset(cutoffX, 0),
        Offset(cutoffX, size.height),
        Paint()
          ..color = AppColors.textTertiary.withValues(alpha: 0.25)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CombinedPainter old) =>
      old.progress != progress ||
      old.result != result ||
      old.history != history;
}

// ── Histogram painter ─────────────────────────────────────────────────────────

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
      final idx =
          ((p - minV) / range * (buckets - 1)).round().clamp(0, buckets - 1);
      counts[idx]++;
    }
    final maxC = counts.reduce(max).toDouble();
    final bw = size.width / buckets;
    for (var i = 0; i < buckets; i++) {
      final h = counts[i] / maxC * size.height;
      final r = Rect.fromLTWH(i * bw + 1, size.height - h, bw - 2, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()
          ..color = accent.withValues(alpha: 0.45 + 0.4 * (counts[i] / maxC)),
      );
    }
  }

  @override
  bool shouldRepaint(_HistPainter old) => old.result != result;
}

// ── Stats strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result, required this.fmt});
  final MonteCarloResult result;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppText.display(
                    size: 16, weight: FontWeight.w700, color: AppColors.mint)),
            Text(label,
                style: AppText.mono(
                    size: 10, color: AppColors.textTertiary, spacing: 0.5)),
          ],
        );

    return Wrap(
      spacing: Insets.xl,
      runSpacing: Insets.md,
      children: [
        stat('Mean', fmt(result.mean)),
        stat('Median', fmt(result.median)),
        stat('P5', fmt(result.p5)),
        stat('P95', fmt(result.p95)),
        stat(
            'Prob. Profit', '${(result.probProfit * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
}
