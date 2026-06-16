import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'game_input.dart';

// ── Game constants ──────────────────────────────────────────────────────────
const _cols = 8;
const _rows = 5;
const _brickW = 56.0;
const _brickH = 20.0;
const _brickGap = 4.0;
const _paddleH = 10.0;
const _ballR = 7.0;
const _maxSpeed = 480.0;

enum _GameState { ready, playing, win, over }

final _palette = [
  AppColors.violet,
  AppColors.cyan,
  AppColors.pink,
  AppColors.mint,
  AppColors.amber,
];

class MiniGame extends StatefulWidget {
  const MiniGame({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<MiniGame> createState() => _MiniGameState();
}

class _MiniGameState extends State<MiniGame>
    with SingleTickerProviderStateMixin, GameKeyboard<MiniGame> {
  late final Ticker _ticker;

  Size _field = const Size(420, 300);
  double _paddleW = 80;
  double _paddleX = 0;
  Offset _ball = Offset.zero;
  Offset _vel = Offset.zero;

  int _score = 0;
  int _lives = 3;
  _GameState _gs = _GameState.ready;

  late List<bool> _bricks;
  double? _mouseX;

  @override
  void initState() {
    super.initState();
    _resetBricks();
    _ticker = createTicker(_tick)..start();
    initGameKeyboard();
  }

  @override
  void onGameKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      _mouseX = null; // hand control back to keyboard
    }
    if (key == LogicalKeyboardKey.space && _gs != _GameState.playing) {
      _startGame();
    }
    if (key == LogicalKeyboardKey.escape) widget.onClose();
  }

  void _resetBricks() {
    _bricks = List.filled(_cols * _rows, true);
  }

  void _startGame() {
    if (_gs == _GameState.playing) return;
    _resetBricks();
    _score = 0;
    _lives = 3;
    _gs = _GameState.playing;
    _initBall();
  }

  void _initBall() {
    final angle = -pi / 2 + (Random().nextDouble() - 0.5) * pi / 4;
    const speed = 240.0;
    _paddleX = (_field.width - _paddleW) / 2;
    _ball = Offset(_field.width / 2, _field.height - 60);
    _vel = Offset(cos(angle) * speed, sin(angle) * speed);
  }

  Duration _lastTime = Duration.zero;

  void _tick(Duration elapsed) {
    if (_gs != _GameState.playing) return;
    if (_lastTime == Duration.zero) { _lastTime = elapsed; return; }
    final dt = ((elapsed - _lastTime).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTime = elapsed;
    _update(dt);
  }

  Offset _gridOrigin() {
    final totalW = _cols * _brickW + (_cols - 1) * _brickGap;
    final ox = (_field.width - totalW) / 2;
    return Offset(ox, 40);
  }

  Rect _brickRect(int col, int row) {
    final o = _gridOrigin();
    return Rect.fromLTWH(
      o.dx + col * (_brickW + _brickGap),
      o.dy + row * (_brickH + _brickGap),
      _brickW,
      _brickH,
    );
  }

  void _update(double dt) {
    // Paddle — mouse takes priority over keys
    if (_mouseX != null) {
      _paddleX = (_mouseX! - _paddleW / 2).clamp(0, _field.width - _paddleW);
    } else {
      const speed = 300.0;
      if (heldKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _paddleX = (_paddleX - speed * dt).clamp(0, _field.width - _paddleW);
      }
      if (heldKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _paddleX = (_paddleX + speed * dt).clamp(0, _field.width - _paddleW);
      }
    }

    Offset next = _ball + _vel * dt;

    // Wall bounce
    if (next.dx - _ballR < 0) { next = Offset(_ballR, next.dy); _vel = Offset(-_vel.dx, _vel.dy); }
    if (next.dx + _ballR > _field.width) { next = Offset(_field.width - _ballR, next.dy); _vel = Offset(-_vel.dx, _vel.dy); }
    if (next.dy - _ballR < 0) { next = Offset(next.dx, _ballR); _vel = Offset(_vel.dx, -_vel.dy); }

    // Paddle
    final paddleRect = Rect.fromLTWH(_paddleX, _field.height - 28, _paddleW, _paddleH);
    if (_vel.dy > 0 &&
        next.dy + _ballR >= paddleRect.top &&
        next.dx >= paddleRect.left &&
        next.dx <= paddleRect.right) {
      final rel = ((next.dx - paddleRect.center.dx) / (_paddleW / 2)).clamp(-1.0, 1.0);
      final angle = rel * pi / 3 - pi / 2;
      final speed = _vel.distance.clamp(220.0, _maxSpeed);
      _vel = Offset(cos(angle) * speed, sin(angle) * speed);
      next = Offset(next.dx, paddleRect.top - _ballR - 1);
    }

    // Brick collision
    for (var i = 0; i < _bricks.length; i++) {
      if (!_bricks[i]) continue;
      final col = i % _cols;
      final row = i ~/ _cols;
      final r = _brickRect(col, row);
      if (_collideBrick(next, r)) {
        _bricks[i] = false;
        _score++;
      }
    }

    if (next.dy > _field.height + _ballR) {
      _lives--;
      if (_lives <= 0) { setState(() { _gs = _GameState.over; _ball = next; }); return; }
      _initBall();
      next = _ball;
    }

    if (_bricks.every((b) => !b)) { setState(() { _gs = _GameState.win; _ball = next; }); return; }
    setState(() => _ball = next);
  }

  bool _collideBrick(Offset ball, Rect r) {
    final closest = Offset(ball.dx.clamp(r.left, r.right), ball.dy.clamp(r.top, r.bottom));
    final dist = (ball - closest).distance;
    if (dist > _ballR) return false;
    final ox = (ball.dx - closest.dx).abs();
    final oy = (ball.dy - closest.dy).abs();
    if (ox < oy || oy < 1) { _vel = Offset(_vel.dx, -_vel.dy); }
    else { _vel = Offset(-_vel.dx, _vel.dy); }
    final spd = (_vel.distance * 1.02).clamp(200.0, _maxSpeed);
    _vel = _vel / _vel.distance * spd;
    return true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    disposeGameKeyboard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelW = context.responsive<double>(mobile: double.infinity, tablet: 480, desktop: 500);

    return Center(
      child: SizedBox(
        width: panelW == double.infinity
            ? MediaQuery.sizeOf(context).width - context.pageGutter * 2
            : panelW,
        height: 480,
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
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, 0),
                      child: Row(
                        children: [
                          Text('BREAKOUT',
                              style: AppText.mono(size: 14, color: AppColors.violet, spacing: 2)),
                          const Spacer(),
                          Text('♥ × $_lives   score: $_score',
                              style: AppText.mono(size: 12, color: AppColors.textSecondary, spacing: 0.5)),
                          const SizedBox(width: Insets.sm),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    // Playfield
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          _field = constraints.biggest;
                          _paddleW = (_field.width * 0.19).clamp(60, 100);
                          if (_gs == _GameState.ready) {
                            _paddleX = (_field.width - _paddleW) / 2;
                            _ball = Offset(_field.width / 2, _field.height - 60);
                          }
                          return MouseRegion(
                            onHover: (e) => _mouseX = e.localPosition.dx,
                            onExit: (_) => _mouseX = null,
                            child: GestureDetector(
                              onTap: () { if (_gs != _GameState.playing) _startGame(); },
                              child: CustomPaint(
                                painter: _GamePainter(
                                  field: _field,
                                  bricks: _bricks,
                                  ball: _ball,
                                  paddleX: _paddleX,
                                  paddleW: _paddleW,
                                  state: _gs,
                                  score: _score,
                                  lives: _lives,
                                  gridOriginFn: _brickRect,
                                ),
                                size: _field,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '← → to move  ·  Space to start  ·  Esc to exit',
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

class _GamePainter extends CustomPainter {
  _GamePainter({
    required this.field,
    required this.bricks,
    required this.ball,
    required this.paddleX,
    required this.paddleW,
    required this.state,
    required this.score,
    required this.lives,
    required this.gridOriginFn,
  });

  final Size field;
  final List<bool> bricks;
  final Offset ball;
  final double paddleX, paddleW;
  final _GameState state;
  final int score, lives;
  final Rect Function(int col, int row) gridOriginFn;

  static final _brickColors = List.generate(_rows, (r) => _palette[r % _palette.length]);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < bricks.length; i++) {
      if (!bricks[i]) continue;
      final col = i % _cols;
      final row = i ~/ _cols;
      final r = gridOriginFn(col, row);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = _brickColors[row].withValues(alpha: 0.85));
    }

    final paddleRect = Rect.fromLTWH(paddleX, size.height - 28, paddleW, _paddleH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, const Radius.circular(5)),
      Paint()..shader = AppColors.auroraGradient.createShader(paddleRect),
    );

    if (state != _GameState.ready) {
      canvas.drawCircle(ball, _ballR + 4,
          Paint()..color = AppColors.cyan.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(ball, _ballR, Paint()..color = AppColors.cyan);
    }

    if (state == _GameState.ready) {
      _drawCenter(canvas, size, 'Press Space / Tap to start', AppColors.textSecondary);
    } else if (state == _GameState.over) {
      _drawCenter(canvas, size, 'Game Over — Score: $score', AppColors.pink);
      _drawSub(canvas, size, 'Space / Tap to restart', AppColors.textTertiary);
    } else if (state == _GameState.win) {
      _drawCenter(canvas, size, 'You cleared it 🎉', AppColors.mint);
      _drawSub(canvas, size, 'Space / Tap to play again', AppColors.textTertiary);
    }
  }

  void _drawCenter(Canvas canvas, Size size, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'monospace', fontSize: 18, color: color, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - 24));
  }

  void _drawSub(Canvas canvas, Size size, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: color)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 + 10));
  }

  @override
  bool shouldRepaint(_GamePainter old) => true;
}
