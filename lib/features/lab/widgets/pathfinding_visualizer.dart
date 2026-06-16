import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

// ── Point ─────────────────────────────────────────────────────────────────────

class _Pt {
  const _Pt(this.r, this.c);
  final int r, c;
  @override
  bool operator ==(Object o) => o is _Pt && o.r == r && o.c == c;
  @override
  int get hashCode => Object.hash(r, c);
}

// ── Search events ─────────────────────────────────────────────────────────────

class _Ev {
  const _Ev(this.type, this.pt);
  final String type; // 'frontier' | 'visit' | 'path'
  final _Pt pt;
}

// ── Search algorithms ─────────────────────────────────────────────────────────

List<_Ev> _runSearch(
  Set<_Pt> walls,
  _Pt start,
  _Pt goal,
  int rows,
  int cols,
  String algo,
) {
  final events = <_Ev>[];

  List<_Pt> neighbors(_Pt p) {
    final nbs = <_Pt>[];
    for (final d in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = p.r + d.$1;
      final nc = p.c + d.$2;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        final nb = _Pt(nr, nc);
        if (!walls.contains(nb)) nbs.add(nb);
      }
    }
    return nbs;
  }

  void reconstructPath(Map<_Pt, _Pt?> came, _Pt cur) {
    _Pt? c = cur;
    final path = <_Pt>[];
    while (c != null) {
      path.insert(0, c);
      c = came[c];
    }
    for (final p in path) {
      events.add(_Ev('path', p));
    }
  }

  if (algo == 'BFS') {
    final queue = <_Pt>[start];
    final visited = <_Pt>{start};
    final came = <_Pt, _Pt?>{start: null};
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      events.add(_Ev('visit', cur));
      if (cur == goal) { reconstructPath(came, goal); return events; }
      for (final nb in neighbors(cur)) {
        if (!visited.contains(nb)) {
          visited.add(nb);
          came[nb] = cur;
          queue.add(nb);
          events.add(_Ev('frontier', nb));
        }
      }
    }
    return events;
  }

  // A* / Dijkstra
  double h(_Pt p) => algo == 'Dijkstra'
      ? 0.0
      : ((p.r - goal.r).abs() + (p.c - goal.c).abs()).toDouble();

  final gScore = <_Pt, double>{start: 0};
  final fScore = <_Pt, double>{start: h(start)};
  final openSet = <_Pt>{start};
  final came = <_Pt, _Pt?>{start: null};

  while (openSet.isNotEmpty) {
    final cur = openSet.reduce(
      (a, b) => (fScore[a] ?? double.infinity) <= (fScore[b] ?? double.infinity) ? a : b,
    );
    openSet.remove(cur);
    events.add(_Ev('visit', cur));
    if (cur == goal) { reconstructPath(came, goal); return events; }
    for (final nb in neighbors(cur)) {
      final tG = (gScore[cur] ?? double.infinity) + 1;
      if (tG < (gScore[nb] ?? double.infinity)) {
        came[nb] = cur;
        gScore[nb] = tG;
        fScore[nb] = tG + h(nb);
        if (!openSet.contains(nb)) {
          openSet.add(nb);
          events.add(_Ev('frontier', nb));
        }
      }
    }
  }
  return events;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class PathfindingVisualizer extends StatefulWidget {
  const PathfindingVisualizer({super.key, this.compact = false});
  final bool compact;

  @override
  State<PathfindingVisualizer> createState() => _PathfindingVisualizerState();
}

class _PathfindingVisualizerState extends State<PathfindingVisualizer>
    with SingleTickerProviderStateMixin {
  int get _rows => widget.compact ? 10 : 14;
  int get _cols => widget.compact ? 16 : 22;

  _Pt get _start => const _Pt(0, 0);
  _Pt get _goal => _Pt(_rows - 1, _cols - 1);

  final Set<_Pt> _walls = {};
  final Set<_Pt> _frontier = {};
  final Set<_Pt> _visited = {};
  final List<_Pt> _path = [];

  List<_Ev> _events = [];
  int _evIdx = 0;
  double _evAccum = 0;
  bool _running = false;
  bool _done = false;
  double _speed = 30.0; // events/sec

  String _algo = 'A*';
  static const _algorithms = ['A*', 'Dijkstra', 'BFS'];

  late Ticker _ticker;
  bool _tickerStarted = false;

  // Drag-to-wall
  bool? _dragDrawing; // true=drawing walls, false=erasing

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

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _run() {
    if (_running) return;
    _frontier.clear();
    _visited.clear();
    _path.clear();
    _events = _runSearch(_walls, _start, _goal, _rows, _cols, _algo);
    _evIdx = 0;
    _evAccum = 0;
    _done = false;
    setState(() => _running = true);
  }

  void _clearWalls() => setState(() {
        _walls.clear();
        _resetSearch();
      });

  void _reset() => setState(() {
        _walls.clear();
        _resetSearch();
      });

  void _resetSearch() {
    _frontier.clear();
    _visited.clear();
    _path.clear();
    _events = [];
    _evIdx = 0;
    _running = false;
    _done = false;
  }

  void _onTick(Duration _) {
    if (!_running) return;
    _evAccum += _speed / 60.0;
    var changed = false;
    while (_evAccum >= 1 && _evIdx < _events.length) {
      _applyEvent(_events[_evIdx++]);
      _evAccum -= 1;
      changed = true;
    }
    if (_evIdx >= _events.length && _running) {
      _running = false;
      _done = true;
    }
    if (changed || _done) setState(() {});
  }

  void _applyEvent(_Ev ev) {
    switch (ev.type) {
      case 'frontier':
        _frontier.add(ev.pt);
      case 'visit':
        _frontier.remove(ev.pt);
        _visited.add(ev.pt);
      case 'path':
        _path.add(ev.pt);
    }
  }

  _Pt? _ptFromOffset(Offset local, Size cellSz) {
    final c = (local.dx / cellSz.width).floor().clamp(0, _cols - 1);
    final r = (local.dy / cellSz.height).floor().clamp(0, _rows - 1);
    return _Pt(r, c);
  }

  void _toggleWall(_Pt pt, bool draw) {
    if (pt == _start || pt == _goal) return;
    setState(() {
      if (draw) {
        _walls.add(pt);
      } else {
        _walls.remove(pt);
      }
      _resetSearch();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pad = widget.compact ? Insets.md : Insets.lg;
    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildControls(),
          const SizedBox(height: Insets.md),
          _buildGrid(),
          const SizedBox(height: Insets.sm),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Algorithm
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _algo,
              dropdownColor: AppColors.surface,
              style: AppText.mono(size: 12, color: AppColors.textPrimary, spacing: 0),
              iconSize: 16,
              icon: const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textTertiary),
              items: _algorithms
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() { _algo = v; _resetSearch(); });
              },
            ),
          ),
        ),
        // Speed slider
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Speed', style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0)),
            SizedBox(
              width: 84,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.mint,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.mint,
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _speed,
                  min: 5,
                  max: 120,
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
            ),
          ],
        ),
        // Run
        _PfBtn(label: '▶ Run', onTap: _running ? null : _run, accent: AppColors.mint, filled: true),
        // Clear walls
        _PfBtn(label: '⊠ Clear walls', onTap: _clearWalls),
        // Reset
        _PfBtn(label: '↺ Reset', onTap: _reset),
        if (_done && _path.isEmpty)
          Text('No path found', style: AppText.mono(size: 11, color: AppColors.pink, spacing: 0)),
      ],
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / _cols;
        final cellH = widget.compact ? 28.0 : 34.0;
        final totalH = cellH * _rows;
        final cellSz = Size(cellW, cellH);

        return GestureDetector(
          onTapDown: (d) {
            final pt = _ptFromOffset(d.localPosition, cellSz);
            if (pt != null) {
              _dragDrawing = !_walls.contains(pt);
              _toggleWall(pt, _dragDrawing!);
            }
          },
          onPanStart: (d) {
            final pt = _ptFromOffset(d.localPosition, cellSz);
            if (pt != null) {
              _dragDrawing ??= !_walls.contains(pt);
              _toggleWall(pt, _dragDrawing!);
            }
          },
          onPanUpdate: (d) {
            final pt = _ptFromOffset(d.localPosition, cellSz);
            if (pt != null && _dragDrawing != null) {
              _toggleWall(pt, _dragDrawing!);
            }
          },
          onPanEnd: (_) => _dragDrawing = null,
          child: RepaintBoundary(
            child: SizedBox(
              width: double.infinity,
              height: totalH,
              child: CustomPaint(
                painter: _GridPainter(
                  rows: _rows,
                  cols: _cols,
                  walls: Set.unmodifiable(_walls),
                  frontier: Set.unmodifiable(_frontier),
                  visited: Set.unmodifiable(_visited),
                  path: List.unmodifiable(_path),
                  start: _start,
                  goal: _goal,
                  cellH: cellH,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _legend('Start', AppColors.mint),
        _legend('Goal', AppColors.pink),
        _legend('Frontier', AppColors.amber),
        _legend('Visited', AppColors.violet),
        _legend('Path', AppColors.cyan),
        _legend('Wall', const Color(0xFF2A2A3A)),
      ],
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: AppText.mono(
                  size: 10, color: AppColors.textTertiary, spacing: 0)),
        ],
      );
}

// ── PF button ──────────────────────────────────────────────────────────────────

class _PfBtn extends StatelessWidget {
  const _PfBtn({required this.label, required this.onTap, this.accent = AppColors.cyan, this.filled = false});
  final String label;
  final VoidCallback? onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: filled ? accent.withOpacity(0.15) : AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(
              color: filled ? accent.withOpacity(0.55) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppText.mono(
                size: 12,
                color: filled ? accent : AppColors.textSecondary,
                spacing: 0),
          ),
        ),
      ),
    );
  }
}

// ── Grid painter ───────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.rows,
    required this.cols,
    required this.walls,
    required this.frontier,
    required this.visited,
    required this.path,
    required this.start,
    required this.goal,
    required this.cellH,
  });

  final int rows, cols;
  final Set<_Pt> walls, frontier, visited;
  final List<_Pt> path;
  final _Pt start, goal;
  final double cellH;

  static const _wallColor = Color(0xFF1E1E2E);
  static const _emptyColor = Color(0xFF151520);

  Color _color(_Pt p) {
    if (p == start) return AppColors.mint;
    if (p == goal) return AppColors.pink;
    if (path.contains(p)) return AppColors.cyan;
    if (visited.contains(p)) return AppColors.violet.withOpacity(0.45);
    if (frontier.contains(p)) return AppColors.amber.withOpacity(0.65);
    if (walls.contains(p)) return _wallColor;
    return _emptyColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    const gap = 1.5;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final pt = _Pt(r, c);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c * cellW + gap,
            r * cellH + gap,
            cellW - gap * 2,
            cellH - gap * 2,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = _color(pt));
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
