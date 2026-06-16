import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _Tick {
  const _Tick(this.at, this.btc, this.eth);
  final DateTime at;
  final double btc;
  final double eth;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Live crypto price dashboard — polls CoinGecko (₹, no key needed, CORS-safe).
/// Falls back to a clearly-labelled simulated stream when offline or rate-limited.
class RealtimeDashboard extends StatefulWidget {
  const RealtimeDashboard({super.key});

  @override
  State<RealtimeDashboard> createState() => _RealtimeDashboardState();
}

class _RealtimeDashboardState extends State<RealtimeDashboard> {
  static const _maxBuffer = 40;
  static const _pollInterval = Duration(seconds: 10);
  static final _rng = Random();

  final List<_Tick> _buffer = [];
  double _btcNow = 0;
  double _ethNow = 0;
  double _btcChange = 0;
  double _ethChange = 0;
  bool _isLive = false;
  bool _paused = false;
  DateTime? _lastUpdated;

  // Simulation state (fallback)
  double _simBtc = 8200000;
  double _simEth = 460000;
  double _simT = 0;

  Timer? _pollTimer;
  Timer? _simTimer;
  bool _started = false;
  bool _fetchInProgress = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (context.reduceMotion) {
      _seedSimulated();
      return;
    }

    // Seed with simulated data immediately, then try to go live
    _seedSimulated();
    _fetchLive();

    // Poll live every 10s
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_paused) _fetchLive();
    });

    // Simulated fallback ticks every 2s (only shows when not live)
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_paused && !_isLive) _tickSimulated();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  void _seedSimulated() {
    for (var i = 0; i < 20; i++) {
      _tickSimulated(seed: true);
    }
  }

  void _tickSimulated({bool seed = false}) {
    _simT += 0.5;
    _simBtc = (8200000 +
            350000 * sin(_simT / 8) +
            120000 * sin(_simT / 3.1) +
            (_rng.nextDouble() - 0.5) * 40000)
        .clamp(6000000, 10000000);
    _simEth = (460000 +
            18000 * sin(_simT / 6) +
            6000 * sin(_simT / 2.3) +
            (_rng.nextDouble() - 0.5) * 3000)
        .clamp(350000, 580000);
    final tick = _Tick(DateTime.now(), _simBtc, _simEth);
    if (seed) {
      _buffer.add(tick);
      if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
      _btcNow = _simBtc;
      _ethNow = _simEth;
    } else {
      setState(() {
        _buffer.add(tick);
        if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
        _btcNow = _simBtc;
        _ethNow = _simEth;
      });
    }
  }

  Future<void> _fetchLive() async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;
    try {
      final uri = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=bitcoin,ethereum&vs_currencies=inr&include_24hr_change=true',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final btc = (j['bitcoin']['inr'] as num).toDouble();
        final eth = (j['ethereum']['inr'] as num).toDouble();
        final btcC = (j['bitcoin']['inr_24h_change'] as num).toDouble();
        final ethC = (j['ethereum']['inr_24h_change'] as num).toDouble();
        if (!_paused) {
          setState(() {
            _btcNow = btc;
            _ethNow = eth;
            _btcChange = btcC;
            _ethChange = ethC;
            _isLive = true;
            _lastUpdated = DateTime.now();
            _buffer.add(_Tick(DateTime.now(), btc, eth));
            if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
          });
        }
      }
    } catch (_) {
      if (mounted && !_isLive) setState(() => _isLive = false);
    } finally {
      _fetchInProgress = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtInr(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _updatedLabel() {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final btcBuf = _buffer.map((t) => t.btc).toList();
    final ethBuf = _buffer.map((t) => t.eth).toList();

    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isLive ? AppColors.mint : AppColors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isLive ? AppColors.mint : AppColors.amber).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isLive
                      ? '● Live · CoinGecko · updated ${_updatedLabel()}'
                      : '◎ Simulated (CoinGecko offline)',
                  style: AppText.mono(
                      size: 11,
                      color: _isLive ? AppColors.mint : AppColors.amber,
                      spacing: 0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _paused = !_paused),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.glassHigh,
                    borderRadius: BorderRadius.circular(Corners.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _paused ? '▶ Resume' : '⏸ Pause',
                    style: AppText.mono(
                        size: 11, color: AppColors.textSecondary, spacing: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),

          // KPI row
          if (isDesktop)
            Row(children: [
              Expanded(child: _kpi('Bitcoin', _fmtInr(_btcNow), _btcChange, AppColors.amber)),
              const SizedBox(width: Insets.md),
              Expanded(child: _kpi('Ethereum', _fmtInr(_ethNow), _ethChange, AppColors.cyan)),
            ])
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kpi('Bitcoin', _fmtInr(_btcNow), _btcChange, AppColors.amber),
                const SizedBox(height: Insets.sm),
                _kpi('Ethereum', _fmtInr(_ethNow), _ethChange, AppColors.cyan),
              ],
            ),
          const SizedBox(height: Insets.md),

          // BTC chart
          Text('Bitcoin ₹',
              style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0.5)),
          const SizedBox(height: 4),
          RepaintBoundary(
            child: SizedBox(
              height: 96,
              child: CustomPaint(
                painter: _LinePainter(data: btcBuf, color: AppColors.amber),
                size: const Size(double.infinity, 96),
              ),
            ),
          ),
          const SizedBox(height: Insets.sm),

          // ETH chart
          Text('Ethereum ₹',
              style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0.5)),
          const SizedBox(height: 4),
          RepaintBoundary(
            child: SizedBox(
              height: 96,
              child: CustomPaint(
                painter: _LinePainter(data: ethBuf, color: AppColors.cyan),
                size: const Size(double.infinity, 96),
              ),
            ),
          ),
          const SizedBox(height: Insets.md),

          // Caption
          Text(
            'Polling every 10 s · a WebSocket feed (in progress with Go) '
            'would make this tick in real time.',
            style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String coin, String price, double change, Color color) {
    final up = change >= 0;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin,
                    style: AppText.mono(
                        size: 11, color: AppColors.textTertiary, spacing: 0.3)),
                const SizedBox(height: 2),
                Text(price,
                    style: AppText.mono(size: 16, color: color, spacing: 0)),
              ],
            ),
          ),
          if (change != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (up ? AppColors.mint : AppColors.pink).withOpacity(0.14),
                borderRadius: BorderRadius.circular(Corners.pill),
                border: Border.all(
                  color: (up ? AppColors.mint : AppColors.pink).withOpacity(0.35),
                ),
              ),
              child: Text(
                '${up ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: AppText.mono(
                  size: 11,
                  color: up ? AppColors.mint : AppColors.pink,
                  spacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Line painter ───────────────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.data, required this.color});
  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min);
    final maxV = data.reduce(max);
    final range = (maxV - minV).abs().clamp(1.0, double.infinity);

    double toY(double v) =>
        size.height - ((v - minV) / range * (size.height - 8) + 4);

    // Grid
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 0.5,
      );
    }

    final step = size.width / (data.length - 1);

    // Fill
    final fill = Path()..moveTo(0, size.height);
    for (var i = 0; i < data.length; i++) {
      fill.lineTo(i * step, toY(data[i]));
    }
    fill.lineTo((data.length - 1) * step, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.12));

    // Line
    final line = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i * step;
      final y = toY(data[i]);
      if (i == 0) line.moveTo(x, y); else line.lineTo(x, y);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Latest dot
    final lx = (data.length - 1) * step;
    final ly = toY(data.last);
    canvas.drawCircle(Offset(lx, ly), 3.5, Paint()..color = color);
    canvas.drawCircle(Offset(lx, ly), 2, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.data.length != data.length;
}
