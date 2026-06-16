import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

// ── Step format ───────────────────────────────────────────────────────────────
// ['compare', i, j]    — highlight both bars
// ['swap', i, j]       — swap bars[i] and bars[j]
// ['overwrite', i, v]  — set bars[i] = v (merge sort)
// ['done', i]          — bar[i] is in its final sorted position

// ── Algorithm blurbs ──────────────────────────────────────────────────────────
const _blurbs = {
  'Bubble':
      'Compares each adjacent pair and bubbles the largest value to the end on every pass. Simple but O(n²).',
  'Selection':
      'Scans for the minimum each pass and places it at the front. Makes the fewest swaps of any O(n²) sort.',
  'Insertion':
      'Builds the sorted array one element at a time by inserting each into its correct position. Great for nearly-sorted data.',
  'Quick':
      'Picks a pivot, partitions around it, and recurses. O(n log n) average — the workhorse of real-world sort libraries.',
  'Merge':
      'Divides in half, sorts each half, then merges. Always O(n log n) — stable and predictable at any size.',
};

// ── Step generators ───────────────────────────────────────────────────────────

List<List<dynamic>> _bubbleSteps(List<int> a) {
  final s = <List<dynamic>>[];
  final arr = [...a];
  for (var i = 0; i < arr.length; i++) {
    for (var j = 0; j < arr.length - 1 - i; j++) {
      s.add(['compare', j, j + 1]);
      if (arr[j] > arr[j + 1]) {
        final t = arr[j]; arr[j] = arr[j + 1]; arr[j + 1] = t;
        s.add(['swap', j, j + 1]);
      }
    }
    s.add(['done', arr.length - 1 - i]);
  }
  return s;
}

List<List<dynamic>> _selectionSteps(List<int> a) {
  final s = <List<dynamic>>[];
  final arr = [...a];
  for (var i = 0; i < arr.length - 1; i++) {
    var minIdx = i;
    for (var j = i + 1; j < arr.length; j++) {
      s.add(['compare', minIdx, j]);
      if (arr[j] < arr[minIdx]) minIdx = j;
    }
    if (minIdx != i) {
      final t = arr[i]; arr[i] = arr[minIdx]; arr[minIdx] = t;
      s.add(['swap', i, minIdx]);
    }
    s.add(['done', i]);
  }
  s.add(['done', arr.length - 1]);
  return s;
}

List<List<dynamic>> _insertionSteps(List<int> a) {
  final s = <List<dynamic>>[];
  final arr = [...a];
  for (var i = 1; i < arr.length; i++) {
    var j = i;
    while (j > 0) {
      s.add(['compare', j - 1, j]);
      if (arr[j] < arr[j - 1]) {
        final t = arr[j]; arr[j] = arr[j - 1]; arr[j - 1] = t;
        s.add(['swap', j - 1, j]);
        j--;
      } else {
        break;
      }
    }
  }
  for (var i = 0; i < arr.length; i++) s.add(['done', i]);
  return s;
}

void _quickPartition(
    List<int> arr, int lo, int hi, List<List<dynamic>> s, Set<int> done) {
  if (lo >= hi) {
    if (lo == hi && !done.contains(lo)) { s.add(['done', lo]); done.add(lo); }
    return;
  }
  var i = lo;
  for (var j = lo; j < hi; j++) {
    s.add(['compare', j, hi]);
    if (arr[j] <= arr[hi]) {
      if (i != j) {
        final t = arr[i]; arr[i] = arr[j]; arr[j] = t;
        s.add(['swap', i, j]);
      }
      i++;
    }
  }
  if (i != hi) {
    final t = arr[i]; arr[i] = arr[hi]; arr[hi] = t;
    s.add(['swap', i, hi]);
  }
  if (!done.contains(i)) { s.add(['done', i]); done.add(i); }
  _quickPartition(arr, lo, i - 1, s, done);
  _quickPartition(arr, i + 1, hi, s, done);
}

List<List<dynamic>> _quickSteps(List<int> a) {
  final s = <List<dynamic>>[];
  final arr = [...a];
  final done = <int>{};
  _quickPartition(arr, 0, arr.length - 1, s, done);
  for (var i = 0; i < arr.length; i++) {
    if (!done.contains(i)) s.add(['done', i]);
  }
  return s;
}

void _mergeSplit(List<int> arr, int lo, int hi, List<List<dynamic>> s) {
  if (lo >= hi) return;
  final mid = (lo + hi) ~/ 2;
  _mergeSplit(arr, lo, mid, s);
  _mergeSplit(arr, mid + 1, hi, s);
  final left = arr.sublist(lo, mid + 1);
  final right = arr.sublist(mid + 1, hi + 1);
  var i = 0, j = 0, k = lo;
  while (i < left.length && j < right.length) {
    s.add(['compare', lo + i, mid + 1 + j]);
    arr[k] = left[i] <= right[j] ? left[i++] : right[j++];
    s.add(['overwrite', k, arr[k]]); k++;
  }
  while (i < left.length) { arr[k] = left[i++]; s.add(['overwrite', k, arr[k]]); k++; }
  while (j < right.length) { arr[k] = right[j++]; s.add(['overwrite', k, arr[k]]); k++; }
}

List<List<dynamic>> _mergeSteps(List<int> a) {
  final s = <List<dynamic>>[];
  final arr = [...a];
  _mergeSplit(arr, 0, arr.length - 1, s);
  for (var i = 0; i < arr.length; i++) s.add(['done', i]);
  return s;
}

List<List<dynamic>> _generateSteps(String algo, List<int> arr) {
  switch (algo) {
    case 'Selection': return _selectionSteps(arr);
    case 'Insertion': return _insertionSteps(arr);
    case 'Quick':     return _quickSteps(arr);
    case 'Merge':     return _mergeSteps(arr);
    default:          return _bubbleSteps(arr);
  }
}

// ── History model ─────────────────────────────────────────────────────────────

class _HistoryEntry {
  const _HistoryEntry({
    required this.step,
    required this.type,
    required this.headline,
    required this.detail,
  });
  final int step;
  final String type;     // 'start' | 'compare' | 'swap' | 'overwrite' | 'done'
  final String headline;
  final String detail;

  Color get color {
    switch (type) {
      case 'compare':   return AppColors.amber;
      case 'swap':      return AppColors.pink;
      case 'done':      return AppColors.mint;
      case 'overwrite': return AppColors.cyan;
      default:          return AppColors.textTertiary;
    }
  }
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Sorting algorithm visualiser.
///
/// Used in two places:
///   - `/lab`          → `SortingVisualizer()`          (default, no history)
///   - project detail  → `SortingVisualizer(showHistory: true)`
///
/// The [showHistory] flag adds a scrollable step-by-step log below the chart.
/// Everything else (bars, controls, status, legend) is identical in both places.
class SortingVisualizer extends StatefulWidget {
  const SortingVisualizer({
    super.key,
    this.compact = false,
    this.showHistory = false,
  });

  final bool compact;

  /// When true, records every comparison/swap/overwrite in a scrollable log
  /// shown below the chart. Has no effect on the visual/animation layer.
  final bool showHistory;

  @override
  State<SortingVisualizer> createState() => _SortingVisualizerState();
}

class _SortingVisualizerState extends State<SortingVisualizer>
    with SingleTickerProviderStateMixin {
  static const _barCount = 18;
  static final _rng = Random();
  static const _algorithms = ['Bubble', 'Selection', 'Insertion', 'Quick', 'Merge'];

  // ── Visual state ──────────────────────────────────────────────────────────
  List<int> _arr = [];
  List<List<dynamic>> _steps = [];
  int _stepIdx = 0;
  double _stepAccum = 0;

  int _cmpA = -1, _cmpB = -1;
  int _swpA = -1, _swpB = -1;
  final Set<int> _sorted = {};

  int _comparisons = 0;
  int _swaps = 0;
  String _status = 'Press Play to start';

  bool _playing = false;
  double _speed = 40;
  String _algo = 'Bubble';

  late Ticker _ticker;
  bool _tickerStarted = false;

  // ── History state (only used when showHistory == true) ────────────────────
  final List<_HistoryEntry> _history = [];
  int _historyStep = 0;
  final ScrollController _histScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tickerStarted) return;
    _tickerStarted = true;
    if (!context.reduceMotion) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _histScroll.dispose();
    super.dispose();
  }

  // ── Control logic ─────────────────────────────────────────────────────────

  void _reset() {
    _arr = List.generate(_barCount, (_) => 10 + _rng.nextInt(91));
    _steps = _generateSteps(_algo, _arr);
    _stepIdx = 0;
    _stepAccum = 0;
    _cmpA = _cmpB = _swpA = _swpB = -1;
    _sorted.clear();
    _comparisons = _swaps = 0;
    _status = 'Press Play to start';
    _playing = false;
    if (widget.showHistory) {
      _history.clear();
      _historyStep = 0;
    }
  }

  void _shuffle() => setState(_reset);

  void _togglePlay() {
    if (_stepIdx >= _steps.length) _reset();
    // Record the starting array when beginning a fresh sort
    if (widget.showHistory && !_playing && _stepIdx == 0) {
      _history.clear();
      _historyStep = 0;
      _history.add(_HistoryEntry(
        step: 0,
        type: 'start',
        headline: '▶  Sort started  ·  $_algo  ·  ${_arr.length} elements',
        detail: 'Initial array:  [${_arr.join(', ')}]',
      ));
    }
    setState(() => _playing = !_playing);
  }

  void _onTick(Duration _) {
    if (!_playing || _stepIdx >= _steps.length) return;
    _stepAccum += _speed / 60.0;
    var changed = false;
    while (_stepAccum >= 1 && _stepIdx < _steps.length) {
      _applyStep(_steps[_stepIdx++]);
      _stepAccum -= 1;
      changed = true;
    }
    if (_stepIdx >= _steps.length) {
      _playing = false;
      _cmpA = _cmpB = _swpA = _swpB = -1;
      _status = 'Sorted ✓';
      if (widget.showHistory) {
        _history.add(_HistoryEntry(
          step: ++_historyStep,
          type: 'done',
          headline: '✓  Sort complete  ·  $_comparisons comparisons  ·  $_swaps swaps',
          detail: 'Final array:  [${_arr.join(', ')}]',
        ));
      }
    }
    if (changed || !_playing) {
      setState(() {});
      if (widget.showHistory && changed) _scrollHistoryToBottom();
    }
  }

  void _applyStep(List<dynamic> step) {
    _cmpA = _cmpB = _swpA = _swpB = -1;
    final type = step[0] as String;

    // ── Record history entry BEFORE mutating the array ─────────────────────
    if (widget.showHistory) {
      _historyStep++;
      _HistoryEntry entry;
      switch (type) {
        case 'compare':
          final i = step[1] as int;
          final j = step[2] as int;
          final vi = _arr[i];
          final vj = _arr[j];
          final outOfOrder = vi > vj;
          entry = _HistoryEntry(
            step: _historyStep,
            type: 'compare',
            headline:
                'Step $_historyStep  ·  Compare  a[$i] = $vi   vs   a[$j] = $vj',
            detail: outOfOrder
                ? '$vi > $vj  →  out of order, swap will follow'
                : '$vi ≤ $vj  →  already in order, no swap',
          );
        case 'swap':
          final i = step[1] as int;
          final j = step[2] as int;
          entry = _HistoryEntry(
            step: _historyStep,
            type: 'swap',
            headline:
                'Step $_historyStep  ·  Swap  a[$i] = ${_arr[i]}  ↔  a[$j] = ${_arr[j]}',
            detail: '${_arr[i]} moves to position $j  ·  ${_arr[j]} moves to position $i',
          );
        case 'overwrite':
          final i = step[1] as int;
          final v = step[2] as int;
          entry = _HistoryEntry(
            step: _historyStep,
            type: 'overwrite',
            headline: 'Step $_historyStep  ·  Write  a[$i]  ←  $v  (merge)',
            detail: 'Previous value ${_arr[i]} replaced during merge',
          );
        default: // 'done'
          final i = step[1] as int;
          entry = _HistoryEntry(
            step: _historyStep,
            type: 'done',
            headline: 'Step $_historyStep  ·  Position $i settled  →  value ${_arr[i]}',
            detail:
                '${_arr[i]} is now in its final sorted position',
          );
      }
      _history.add(entry);
      if (_history.length > 600) _history.removeAt(1); // keep 'start' at index 0
    }

    // ── Apply the step (mutates _arr) ───────────────────────────────────────
    switch (type) {
      case 'compare':
        _cmpA = step[1] as int;
        _cmpB = step[2] as int;
        _comparisons++;
        _status =
            'Comparing a[$_cmpA] = ${_arr[_cmpA]}  and  a[$_cmpB] = ${_arr[_cmpB]}';
      case 'swap':
        final i = step[1] as int;
        final j = step[2] as int;
        _swpA = i; _swpB = j;
        _status = 'Swapping a[$i] = ${_arr[i]}  ↔  a[$j] = ${_arr[j]}';
        final t = _arr[i]; _arr[i] = _arr[j]; _arr[j] = t;
        _swaps++;
      case 'overwrite':
        _arr[step[1] as int] = step[2] as int;
        _status = 'Writing ${step[2]}  →  a[${step[1]}]  (merge)';
      case 'done':
        _sorted.add(step[1] as int);
        _status = 'Position ${step[1]} settled  →  value ${_arr[step[1] as int]}';
    }
  }

  void _scrollHistoryToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_histScroll.hasClients &&
          _histScroll.position.hasContentDimensions) {
        _histScroll.animateTo(
          _histScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chartHeight = widget.compact ? 130.0 : 180.0;
    final done = _stepIdx >= _steps.length && _steps.isNotEmpty;
    final pad = widget.compact
        ? Insets.sm
        : context.responsive<double>(mobile: Insets.sm, desktop: Insets.md);

    final column = Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Controls ──────────────────────────────────────────────────
          _buildControls(done),
          if (!widget.compact) ...[
            const SizedBox(height: Insets.sm),
            Text(
              _blurbs[_algo] ?? '',
              style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.2),
            ),
          ],
          const SizedBox(height: Insets.sm),
          // ── Live status ───────────────────────────────────────────────
          Text(
            _status,
            style: AppText.mono(size: 12, color: AppColors.textSecondary, spacing: 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Insets.sm),
          // ── Bar chart ─────────────────────────────────────────────────
          RepaintBoundary(
            child: SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarPainter(
                  array: List.unmodifiable(_arr),
                  cmpA: _cmpA,
                  cmpB: _cmpB,
                  swpA: _swpA,
                  swpB: _swpB,
                  sorted: Set.unmodifiable(_sorted),
                  showLabels: !widget.compact,
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.sm),
          // ── Legend + counters ─────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _swatch('Comparing', AppColors.amber),
              _swatch('Swapping', AppColors.pink),
              _swatch('Sorted', AppColors.mint),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _counter('${_comparisons}c', AppColors.amber),
                  const SizedBox(width: 10),
                  _counter('${_swaps}s', AppColors.pink),
                ],
              ),
            ],
          ),

          // ── Step history (project detail only) ────────────────────────
          if (widget.showHistory) ...[
            const SizedBox(height: Insets.xl),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Text('Step History',
                    style: AppText.display(size: 16, weight: FontWeight.w600)),
                const SizedBox(width: Insets.sm),
                if (_history.isNotEmpty)
                  Text(
                    '${_history.length - 1} steps recorded',
                    style: AppText.mono(
                        size: 11, color: AppColors.textTertiary, spacing: 0),
                  ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            _history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: Insets.md),
                    child: Text(
                      'Press ▶ Play to start recording every comparison, swap and overwrite.',
                      style: AppText.mono(
                          size: 12, color: AppColors.textTertiary, spacing: 0),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassHigh,
                        borderRadius: BorderRadius.circular(Corners.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        controller: _histScroll,
                        padding: const EdgeInsets.all(Insets.md),
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppColors.border,
                          height: 10,
                          indent: 14,
                        ),
                        itemBuilder: (_, i) =>
                            _HistoryEntryTile(entry: _history[i]),
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );

    // Lab section: plain column (unchanged behaviour).
    // Project detail (showHistory): wrap in SingleChildScrollView so the
    // column can be taller than the ConstrainedBox that wraps the demo block.
    if (widget.showHistory) {
      return SingleChildScrollView(child: column);
    }
    return column;
  }

  Widget _buildControls(bool done) {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AlgoDropdown(
          value: _algo,
          algorithms: _algorithms,
          onChanged: (v) {
            setState(() { _algo = v; _reset(); _steps = _generateSteps(_algo, _arr); });
          },
        ),
        _SpeedRow(
          value: _speed,
          onChanged: (v) => setState(() => _speed = v),
        ),
        _ControlBtn(label: '⟳  Shuffle', onTap: _shuffle, accent: AppColors.cyan),
        _ControlBtn(
          label: _playing ? '⏸  Pause' : (done ? '↺  Replay' : '▶  Play'),
          onTap: _togglePlay,
          filled: true,
        ),
      ],
    );
  }

  Widget _swatch(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: AppText.mono(size: 10, color: AppColors.textTertiary, spacing: 0)),
        ],
      );

  Widget _counter(String label, Color color) =>
      Text(label, style: AppText.mono(size: 12, color: color, spacing: 0));
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AlgoDropdown extends StatelessWidget {
  const _AlgoDropdown(
      {required this.value, required this.algorithms, required this.onChanged});
  final String value;
  final List<String> algorithms;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.glassHigh,
        borderRadius: BorderRadius.circular(Corners.md),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface,
          style: AppText.mono(size: 12, color: AppColors.textPrimary, spacing: 0),
          iconSize: 16,
          icon: const Icon(Icons.expand_more_rounded,
              size: 16, color: AppColors.textTertiary),
          items: algorithms
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Speed',
            style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0)),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.violet,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.violet,
              overlayColor: AppColors.violet.withOpacity(0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 5,
              max: 200,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.label,
    required this.onTap,
    this.accent = AppColors.violet,
    this.filled = false,
  });
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? accent.withOpacity(0.18) : AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.md),
          border:
              Border.all(color: filled ? accent.withOpacity(0.6) : AppColors.border),
        ),
        child: Text(label,
            style: AppText.mono(
                size: 12,
                color: filled ? accent : AppColors.textSecondary,
                spacing: 0)),
      ),
    );
  }
}

// ── Bar painter ────────────────────────────────────────────────────────────────

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.array,
    required this.cmpA,
    required this.cmpB,
    required this.swpA,
    required this.swpB,
    required this.sorted,
    this.showLabels = true,
  });

  final List<int> array;
  final int cmpA, cmpB, swpA, swpB;
  final Set<int> sorted;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (array.isEmpty) return;
    final maxVal = array.reduce(max);
    final n = array.length;
    final barW = size.width / n;
    final gap = (barW * 0.15).clamp(1.5, 5.0);
    final labelH = showLabels ? 14.0 : 0.0;
    final chartH = size.height - labelH;

    for (var i = 0; i < n; i++) {
      final h = (array[i] / maxVal) * chartH;
      final x = i * barW + gap / 2;
      final w = barW - gap;
      final rect = Rect.fromLTWH(x, chartH - h, w, h);

      final Color color;
      if (i == swpA || i == swpB)      color = AppColors.pink;
      else if (i == cmpA || i == cmpB) color = AppColors.amber;
      else if (sorted.contains(i))     color = AppColors.mint;
      else                             color = AppColors.violet.withOpacity(0.65);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = color,
      );

      if (showLabels && w > 10) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${array[i]}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w);
        if (tp.width <= w) {
          tp.paint(canvas, Offset(x + (w - tp.width) / 2, chartH - h - tp.height - 1));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}

// ── History tile ───────────────────────────────────────────────────────────────

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});
  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent bar
        Container(
          width: 3,
          height: 34,
          margin: const EdgeInsets.only(right: 10, top: 1),
          decoration: BoxDecoration(
            color: entry.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.headline,
                style: AppText.mono(
                    size: 11, color: entry.color, spacing: 0),
              ),
              const SizedBox(height: 2),
              Text(
                entry.detail,
                style: AppText.mono(
                    size: 10, color: AppColors.textTertiary, spacing: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
