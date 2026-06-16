import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/magnetic_button.dart';

/// Interactive recreation of the Polaris government smart-energy app.
/// Dummy data, ₹. Set [preview] = true for a compact non-interactive
/// gauge-only view (used in the hero phone frame).
class SmartMeterDemo extends StatefulWidget {
  const SmartMeterDemo({super.key, this.preview = false});
  final bool preview;

  @override
  State<SmartMeterDemo> createState() => _SmartMeterDemoState();
}

class _SmartMeterDemoState extends State<SmartMeterDemo>
    with TickerProviderStateMixin {
  // Balance (animated on recharge)
  double _prevBalance = 1234.50;
  double _balance = 1234.50;

  // Live gauge values
  double _load = 2.4; // kW
  double _todayKwh = 7.3;

  late final Ticker _ticker;
  bool _tickerStarted = false;

  // 7-day chart
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayUnits = [5.2, 6.8, 7.1, 4.9, 8.3, 9.1, 7.3];
  static const _ratePerUnit = 8.5;
  int _selectedDay = 6;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tickerStarted) return;
    _tickerStarted = true;
    if (!context.reduceMotion) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final t = elapsed.inMilliseconds / 1000.0;
    setState(() {
      _load =
          (2.4 + sin(t * 0.31) * 0.62 + sin(t * 0.77) * 0.22).clamp(0.5, 5.0);
      _todayKwh = 7.3 + t * _load / 3600.0;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _recharge(double amount) {
    setState(() {
      _prevBalance = _balance;
      _balance += amount;
    });
  }

  void _openRechargeSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RechargeSheet(onConfirm: _recharge),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.preview ? _buildPreview() : _buildFull(context);
  }

  // ── Preview (hero phone) ───────────────────────────────────────────────────

  Widget _buildPreview() {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          // Status + balance strip
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPPCL · 1180 0423',
                      style: AppText.mono(
                          size: 8, color: AppColors.textTertiary, spacing: 0),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_balance),
                      duration: const Duration(milliseconds: 700),
                      tween: Tween(begin: _prevBalance, end: _balance),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '₹${v.toStringAsFixed(0)}',
                        style: AppText.display(size: 15, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Corners.pill),
                    border: Border.all(color: AppColors.mint.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: AppColors.mint, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Text('ON',
                        style: AppText.mono(
                            size: 7, color: AppColors.mint, spacing: 0)),
                  ]),
                ),
              ],
            ),
          ),
          // Gauge fills remaining space
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GaugePainter(
                  value: _load,
                  maxValue: 5.0,
                  color: AppColors.violet,
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('${_load.toStringAsFixed(1)} kW', 'Load',
                    AppColors.violet),
                _miniStat(
                    '${_todayKwh.toStringAsFixed(1)} kWh', 'Today', AppColors.mint),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: AppText.mono(size: 11, color: color, spacing: 0)),
          Text(label,
              style: AppText.mono(
                  size: 8, color: AppColors.textTertiary, spacing: 0)),
        ],
      );

  // ── Full demo (detail page) ────────────────────────────────────────────────

  Widget _buildFull(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: Insets.sm),
          _buildGaugeCard(),
          const SizedBox(height: Insets.sm),
          _buildChartCard(),
          const SizedBox(height: Insets.md),
          MagneticButton(
            label: '⚡  Recharge',
            filled: true,
            onPressed: () => _openRechargeSheet(context),
          ),
          const SizedBox(height: Insets.md),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding:
          const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPPCL · 1180 0423 9921',
                  style: AppText.mono(
                      size: 11, color: AppColors.textTertiary, spacing: 0.2),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  key: ValueKey(_balance),
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: _prevBalance, end: _balance),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '₹${v.toStringAsFixed(2)}',
                    style: AppText.display(size: 26, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(Corners.pill),
              border: Border.all(color: AppColors.mint.withOpacity(0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Connected',
                  style:
                      AppText.mono(size: 11, color: AppColors.mint, spacing: 0)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard() {
    return GlassContainer(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: _load,
                      maxValue: 5.0,
                      color: AppColors.violet,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('${_load.toStringAsFixed(2)} kW', 'Current Load',
                  AppColors.violet),
              _stat('${_todayKwh.toStringAsFixed(2)} kWh', 'Today',
                  AppColors.mint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: AppText.mono(size: 14, color: color, spacing: 0)),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.mono(
                  size: 11, color: AppColors.textTertiary, spacing: 0)),
        ],
      );

  Widget _buildChartCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-Day Usage',
              style: AppText.display(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: Insets.sm),
          _BarChart(
            dayLabels: _dayLabels,
            dayUnits: _dayUnits,
            selectedDay: _selectedDay,
            ratePerUnit: _ratePerUnit,
            onDaySelected: (i) => setState(() => _selectedDay = i),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            '${_dayLabels[_selectedDay]}: '
            '${_dayUnits[_selectedDay].toStringAsFixed(1)} kWh '
            '(₹${(_dayUnits[_selectedDay] * _ratePerUnit).toStringAsFixed(0)})',
            style: AppText.mono(size: 12, color: AppColors.textSecondary, spacing: 0),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.dayLabels,
    required this.dayUnits,
    required this.selectedDay,
    required this.ratePerUnit,
    required this.onDaySelected,
  });

  final List<String> dayLabels;
  final List<double> dayUnits;
  final int selectedDay;
  final double ratePerUnit;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final maxUnit = dayUnits.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < dayLabels.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onDaySelected(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      height: 56 * (dayUnits[i] / maxUnit),
                      decoration: BoxDecoration(
                        color: i == selectedDay
                            ? AppColors.violet
                            : AppColors.violet.withOpacity(0.28),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabels[i],
                      style: AppText.mono(
                        size: 10,
                        color: i == selectedDay
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        spacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < dayLabels.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

// ── Gauge painter ──────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final double value;
  final double maxValue;
  final Color color;

  static const _startAngle = 5 * pi / 6; // 150°
  static const _totalSweep = 4 * pi / 3; // 240°

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final minDim = min(size.width, size.height);
    final radius = (minDim / 2) - stroke / 2 - 8;
    final center = Offset(size.width / 2, size.height * 0.54);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progress = (value / maxValue).clamp(0.0, 1.0);

    // Background track
    canvas.drawArc(
      rect,
      _startAngle,
      _totalSweep,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc
    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        _totalSweep * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Needle
    final needleAngle = _startAngle + _totalSweep * progress;
    final needleLen = radius * 0.66;
    final tip = center +
        Offset(cos(needleAngle) * needleLen, sin(needleAngle) * needleLen);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Center hub
    canvas.drawCircle(center, 5, Paint()..color = color);
    canvas.drawCircle(
        center, 3.5, Paint()..color = const Color(0xFF0D0D1A));

    // Value label inside gauge
    final textSpan = TextSpan(
      text: '${value.toStringAsFixed(1)}\nkW',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.90),
        height: 1.3,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        center + Offset(-tp.width / 2, radius * 0.22 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ── Recharge sheet ─────────────────────────────────────────────────────────────

class _RechargeSheet extends StatefulWidget {
  const _RechargeSheet({required this.onConfirm});
  final ValueChanged<double> onConfirm;

  @override
  State<_RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends State<_RechargeSheet> {
  static const _presets = [100.0, 200.0, 500.0];
  double _selected = 200.0;
  bool _confirmed = false;

  void _confirm() {
    widget.onConfirm(_selected);
    setState(() => _confirmed = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Corners.lg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(Insets.lg),
        child: _confirmed ? _buildSuccess() : _buildInput(),
      ),
    );
  }

  Widget _buildInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recharge Balance',
            style: AppText.display(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: Insets.md),
        // Amount chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final p in _presets)
              GestureDetector(
                onTap: () => setState(() => _selected = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _selected == p
                        ? AppColors.violet.withOpacity(0.18)
                        : AppColors.glass,
                    borderRadius: BorderRadius.circular(Corners.pill),
                    border: Border.all(
                      color: _selected == p
                          ? AppColors.violet
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '₹${p.toInt()}',
                    style: AppText.mono(
                      size: 13,
                      color: _selected == p
                          ? AppColors.violet
                          : AppColors.textSecondary,
                      spacing: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        MagneticButton(
          label: 'Confirm  ₹${_selected.toInt()}',
          filled: true,
          onPressed: _confirm,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Insets.md),
        const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 52),
        const SizedBox(height: Insets.md),
        Text('Recharged!',
            style: AppText.display(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: Insets.sm),
        Text(
          '₹${_selected.toInt()} added to your meter balance.',
          style: AppText.body(size: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.lg),
      ],
    );
  }
}
