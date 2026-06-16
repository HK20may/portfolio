import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../game_input.dart';

// ── Snake game ───────────────────────────────────────────────────────────────
enum _Dir { up, down, left, right }

extension on _Dir {
  int get dx => switch (this) { _Dir.left => -1, _Dir.right => 1, _ => 0 };
  int get dy => switch (this) { _Dir.up => -1, _Dir.down => 1, _ => 0 };
  bool opposes(_Dir o) =>
      (this == _Dir.up && o == _Dir.down) ||
      (this == _Dir.down && o == _Dir.up) ||
      (this == _Dir.left && o == _Dir.right) ||
      (this == _Dir.right && o == _Dir.left);
}

enum _Gs { ready, playing, over }

const _grid = 20;
const _initInterval = 0.13; // seconds per step

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame>
    with SingleTickerProviderStateMixin, GameKeyboard<SnakeGame> {
  late final Ticker _ticker;

  List<Point<int>> _snake = [];
  Point<int>? _food;
  _Dir _dir = _Dir.right;
  _Dir _next = _Dir.right;
  _Gs _gs = _Gs.ready;
  int _score = 0;
  double _stepAccum = 0;
  double _stepInterval = _initInterval;

  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    initGameKeyboard();
    _ticker = createTicker(_tick)..start();
    _reset();
  }

  void _reset() {
    _snake = [
      const Point(10, 10),
      const Point(9, 10),
      const Point(8, 10),
    ];
    _dir = _Dir.right;
    _next = _Dir.right;
    _score = 0;
    _stepAccum = 0;
    _stepInterval = _initInterval;
    _gs = _Gs.ready;
    _spawnFood();
    setState(() {});
  }

  void _spawnFood() {
    final rng = Random();
    Point<int> f;
    do {
      f = Point(rng.nextInt(_grid), rng.nextInt(_grid));
    } while (_snake.contains(f));
    _food = f;
  }

  @override
  void onGameKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) { widget.onClose(); return; }
    if (key == LogicalKeyboardKey.space && _gs != _Gs.playing) {
      setState(() => _gs = _Gs.playing);
      return;
    }
    final d = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => _Dir.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => _Dir.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => _Dir.left,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => _Dir.right,
      _ => null,
    };
    if (d != null && !d.opposes(_dir)) _next = d;
  }

  void _tick(Duration elapsed) {
    if (_gs != _Gs.playing) return;
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    _stepAccum += dt;
    while (_stepAccum >= _stepInterval) {
      _stepAccum -= _stepInterval;
      _step();
    }
  }

  void _step() {
    _dir = _next;
    final head = _snake.first;
    final nh = Point(head.x + _dir.dx, head.y + _dir.dy);

    if (nh.x < 0 || nh.x >= _grid || nh.y < 0 || nh.y >= _grid ||
        _snake.contains(nh)) {
      setState(() => _gs = _Gs.over);
      return;
    }

    _snake = [nh, ..._snake];
    if (nh == _food) {
      _score++;
      _stepInterval = (_stepInterval * 0.97).clamp(0.055, _initInterval);
      _spawnFood();
    } else {
      _snake = _snake.sublist(0, _snake.length - 1);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    disposeGameKeyboard();
    super.dispose();
  }

  Offset? _swipeStart;

  @override
  Widget build(BuildContext context) {
    final pw = context.responsive<double>(mobile: double.infinity, tablet: 420, desktop: 440);
    return Center(
      child: SizedBox(
        width: pw == double.infinity ? MediaQuery.sizeOf(context).width - context.pageGutter * 2 : pw,
        height: 500,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corners.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE6060610),
                borderRadius: BorderRadius.circular(Corners.lg),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Focus(
                focusNode: gameFocus,
                autofocus: true,
                onKeyEvent: handleGameKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, 0),
                      child: Row(
                        children: [
                          Text('SNAKE', style: AppText.mono(size: 14, color: AppColors.mint, spacing: 2)),
                          const Spacer(),
                          Text('score: $_score', style: AppText.mono(size: 12, color: AppColors.textSecondary, spacing: 0.5)),
                          const SizedBox(width: Insets.sm),
                          GestureDetector(onTap: widget.onClose,
                              child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    Expanded(
                      child: GestureDetector(
                        onPanStart: (d) => _swipeStart = d.localPosition,
                        onPanEnd: (d) {
                          if (_swipeStart == null) return;
                          final v = d.velocity.pixelsPerSecond;
                          if (v.distance < 100) return;
                          final dir = v.dx.abs() > v.dy.abs()
                              ? (v.dx > 0 ? _Dir.right : _Dir.left)
                              : (v.dy > 0 ? _Dir.down : _Dir.up);
                          if (!dir.opposes(_dir)) _next = dir;
                          if (_gs == _Gs.ready) setState(() => _gs = _Gs.playing);
                        },
                        onTap: () {
                          if (_gs != _Gs.playing) setState(() {
                            if (_gs == _Gs.over) _reset();
                            else _gs = _Gs.playing;
                          });
                        },
                        child: LayoutBuilder(
                          builder: (ctx, c) => RepaintBoundary(
                            child: CustomPaint(
                              painter: _SnakePainter(
                                snake: _snake,
                                food: _food,
                                gs: _gs,
                                score: _score,
                              ),
                              size: c.biggest,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Arrow / WASD  ·  Space to start  ·  Esc to exit',
                        style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  const _SnakePainter({required this.snake, required this.food, required this.gs, required this.score});
  final List<Point<int>> snake;
  final Point<int>? food;
  final _Gs gs;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;

    // Grid
    final gp = Paint()..color = AppColors.border.withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (var i = 0; i <= _grid; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), gp);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), gp);
    }

    // Food
    if (food != null) {
      final fc = Offset(food!.x * cell + cell / 2, food!.y * cell + cell / 2);
      canvas.drawCircle(fc, cell * 0.35,
          Paint()..color = AppColors.pink..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(fc, cell * 0.25, Paint()..color = AppColors.pink);
    }

    // Snake
    for (var i = 0; i < snake.length; i++) {
      final s = snake[i];
      final t = 1 - i / snake.length;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.x * cell + 1.5, s.y * cell + 1.5, cell - 3, cell - 3),
        Radius.circular(cell * 0.3),
      );
      canvas.drawRRect(r,
          Paint()..color = Color.lerp(AppColors.mint.withValues(alpha: 0.5), AppColors.mint, t)!);
    }

    // Overlay text
    if (gs == _Gs.ready) _drawMsg(canvas, size, 'Space / Tap to start', AppColors.textSecondary);
    if (gs == _Gs.over) {
      _drawMsg(canvas, size, 'Game Over — Score: $score', AppColors.pink);
      _drawSub(canvas, size, 'Tap to restart', AppColors.textTertiary);
    }
  }

  void _drawMsg(Canvas canvas, Size s, String t, Color c) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontFamily: 'monospace', fontSize: 18, color: c, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout(maxWidth: s.width);
    tp.paint(canvas, Offset((s.width - tp.width) / 2, s.height / 2 - 20));
  }

  void _drawSub(Canvas canvas, Size s, String t, Color c) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c)), textDirection: TextDirection.ltr)..layout(maxWidth: s.width);
    tp.paint(canvas, Offset((s.width - tp.width) / 2, s.height / 2 + 8));
  }

  @override
  bool shouldRepaint(_SnakePainter old) => true;
}
