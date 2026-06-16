import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../game_input.dart';

class G2048 extends StatefulWidget {
  const G2048({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<G2048> createState() => _G2048State();
}

class _G2048State extends State<G2048>
    with SingleTickerProviderStateMixin, GameKeyboard<G2048> {
  // Ticker needed by GameKeyboard mixin
  @override
  Ticker createTicker(TickerCallback onTick) => super.createTicker(onTick);

  List<List<int>> _board = List.generate(4, (_) => List.filled(4, 0));
  List<List<bool>> _merged = List.generate(4, (_) => List.filled(4, false));
  List<List<bool>> _isNew = List.generate(4, (_) => List.filled(4, false));
  int _score = 0;
  bool _won = false, _lost = false;

  @override
  void initState() {
    super.initState();
    initGameKeyboard();
    _reset();
  }

  void _reset() {
    _board = List.generate(4, (_) => List.filled(4, 0));
    _merged = List.generate(4, (_) => List.filled(4, false));
    _isNew = List.generate(4, (_) => List.filled(4, false));
    _score = 0;
    _won = false;
    _lost = false;
    _spawn();
    _spawn();
    setState(() {});
  }

  void _spawn() {
    final empty = [
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 4; c++)
          if (_board[r][c] == 0) (r, c)
    ];
    if (empty.isEmpty) return;
    final pos = empty[Random().nextInt(empty.length)];
    _board[pos.$1][pos.$2] = Random().nextDouble() < 0.9 ? 2 : 4;
    _isNew[pos.$1][pos.$2] = true;
  }

  static (List<int>, int, bool) _collapse(List<int> line) {
    final nz = line.where((v) => v != 0).toList();
    final out = <int>[];
    var gained = 0;
    for (var i = 0; i < nz.length; i++) {
      if (i + 1 < nz.length && nz[i] == nz[i + 1]) {
        final m = nz[i] * 2;
        out.add(m);
        gained += m;
        i++;
      } else {
        out.add(nz[i]);
      }
    }
    while (out.length < 4) out.add(0);
    final eq = List.generate(4, (i) => out[i] == line[i]).every((v) => v);
    return (out, gained, !eq);
  }

  void _move(int dr, int dc) {
    if (_won || _lost) return;
    bool anyChanged = false;
    int gained = 0;
    final newBoard = List.generate(4, (r) => List<int>.from(_board[r]));
    final newMerged = List.generate(4, (_) => List<bool>.filled(4, false));
    final newIsNew = List.generate(4, (_) => List<bool>.filled(4, false));

    if (dr == 0) {
      for (var r = 0; r < 4; r++) {
        var row = newBoard[r].toList();
        if (dc > 0) row = row.reversed.toList();
        final (o, g, ch) = _collapse(row);
        if (ch) {
          anyChanged = true;
          gained += g;
        }
        final final_ = dc > 0 ? o.reversed.toList() : o;
        for (var c = 0; c < 4; c++) {
          if (final_[c] != 0 && final_[c] != _board[r][c])
            newMerged[r][c] = true;
          newBoard[r][c] = final_[c];
        }
      }
    } else {
      for (var c = 0; c < 4; c++) {
        var col = [
          newBoard[0][c],
          newBoard[1][c],
          newBoard[2][c],
          newBoard[3][c]
        ];
        if (dr > 0) col = col.reversed.toList();
        final (o, g, ch) = _collapse(col);
        if (ch) {
          anyChanged = true;
          gained += g;
        }
        final final_ = dr > 0 ? o.reversed.toList() : o;
        for (var r = 0; r < 4; r++) {
          if (final_[r] != 0 && final_[r] != _board[r][c])
            newMerged[r][c] = true;
          newBoard[r][c] = final_[r];
        }
      }
    }

    if (!anyChanged) return;
    _board = newBoard;
    _score += gained;
    _merged = newMerged;
    _spawn();
    _isNew = newIsNew;

    if (_board.any((r) => r.any((v) => v >= 2048)))
      _won = true;
    else if (!_canMove()) _lost = true;

    setState(() {});

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted)
        setState(() {
          _merged = List.generate(4, (_) => List.filled(4, false));
          _isNew = List.generate(4, (_) => List.filled(4, false));
        });
    });
  }

  bool _canMove() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_board[r][c] == 0) return true;
        if (c + 1 < 4 && _board[r][c] == _board[r][c + 1]) return true;
        if (r + 1 < 4 && _board[r][c] == _board[r + 1][c]) return true;
      }
    }
    return false;
  }

  @override
  void onGameKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _reset();
      return;
    }
    final dir = switch (key) {
      LogicalKeyboardKey.arrowLeft => (0, -1),
      LogicalKeyboardKey.arrowRight => (0, 1),
      LogicalKeyboardKey.arrowUp => (-1, 0),
      LogicalKeyboardKey.arrowDown => (1, 0),
      _ => null,
    };
    if (dir != null) _move(dir.$1, dir.$2);
  }

  @override
  void dispose() {
    disposeGameKeyboard();
    super.dispose();
  }

  Offset _panStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final pw = context.responsive<double>(
        mobile: double.infinity, tablet: 400, desktop: 420);
    return Center(
      child: SizedBox(
        width: pw == double.infinity
            ? MediaQuery.sizeOf(context).width - context.pageGutter * 2
            : pw,
        height: 520,
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
                      padding: const EdgeInsets.fromLTRB(
                          Insets.lg, Insets.md, Insets.sm, 0),
                      child: Row(
                        children: [
                          Text('2048',
                              style: AppText.mono(
                                  size: 14,
                                  color: AppColors.amber,
                                  spacing: 2)),
                          const Spacer(),
                          Text('score: $_score',
                              style: AppText.mono(
                                  size: 12,
                                  color: AppColors.textSecondary,
                                  spacing: 0.5)),
                          const SizedBox(width: Insets.sm),
                          GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.textTertiary, size: 20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    Expanded(
                      child: GestureDetector(
                        onPanStart: (d) => _panStart = d.localPosition,
                        onPanEnd: (d) {
                          final v = d.velocity.pixelsPerSecond;
                          if (v.distance < 80) return;
                          if (v.dx.abs() > v.dy.abs()) {
                            _move(0, v.dx > 0 ? 1 : -1);
                          } else {
                            _move(v.dy > 0 ? 1 : -1, 0);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Insets.md),
                          child: Stack(
                            children: [
                              // Grid background
                              GridView.count(
                                crossAxisCount: 4,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (var i = 0; i < 16; i++)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.4),
                                        borderRadius:
                                            BorderRadius.circular(Corners.sm),
                                      ),
                                    ),
                                ],
                              ),
                              // Tiles
                              LayoutBuilder(
                                builder: (ctx, c) {
                                  const gap = 6.0;
                                  final cell = (c.maxWidth - gap * 3) / 4;
                                  return Stack(
                                    children: [
                                      for (var r = 0; r < 4; r++)
                                        for (var col = 0; col < 4; col++)
                                          if (_board[r][col] != 0)
                                            AnimatedPositioned(
                                              key: ValueKey(
                                                  '$r-$col-${_board[r][col]}'),
                                              duration: context.reduceMotion
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 120),
                                              curve: Curves.easeOutCubic,
                                              left: col * (cell + gap),
                                              top: r * (cell + gap),
                                              width: cell,
                                              height: cell,
                                              child: AnimatedScale(
                                                scale: (_merged[r][col] ||
                                                        _isNew[r][col])
                                                    ? 1.08
                                                    : 1.0,
                                                duration: const Duration(
                                                    milliseconds: 100),
                                                curve: Curves.easeOutBack,
                                                child: _TileWidget(
                                                    value: _board[r][col]),
                                              ),
                                            ),
                                    ],
                                  );
                                },
                              ),
                              // Win/lose overlay
                              if (_won || _lost)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.background
                                          .withValues(alpha: 0.75),
                                      borderRadius:
                                          BorderRadius.circular(Corners.sm),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            _won ? '2048! 🎉' : 'No more moves',
                                            style: AppText.display(
                                                size: 28,
                                                weight: FontWeight.w800,
                                                color: _won
                                                    ? AppColors.amber
                                                    : AppColors.pink)),
                                        const SizedBox(height: Insets.md),
                                        Text('Score: $_score',
                                            style: AppText.body(
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: Insets.lg),
                                        GestureDetector(
                                          onTap: _reset,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassHigh,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Corners.pill),
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            child: Text('New Game',
                                                style: AppText.body(
                                                    size: 15,
                                                    weight: FontWeight.w600)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Arrows / swipe  ·  R to restart  ·  Esc to exit',
                        style: AppText.mono(
                            size: 11,
                            color: AppColors.textTertiary,
                            spacing: 0.3),
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

class _TileWidget extends StatelessWidget {
  const _TileWidget({required this.value});
  final int value;

  Color get _color {
    if (value <= 2) return AppColors.surface;
    if (value <= 4) return AppColors.cyan.withValues(alpha: 0.25);
    if (value <= 8) return AppColors.mint.withValues(alpha: 0.35);
    if (value <= 16) return AppColors.mint.withValues(alpha: 0.55);
    if (value <= 32) return AppColors.amber.withValues(alpha: 0.35);
    if (value <= 64) return AppColors.amber.withValues(alpha: 0.55);
    if (value <= 128) return AppColors.amber.withValues(alpha: 0.75);
    if (value <= 256) return AppColors.pink.withValues(alpha: 0.45);
    if (value <= 512) return AppColors.pink.withValues(alpha: 0.65);
    if (value <= 1024) return AppColors.violet.withValues(alpha: 0.65);
    return AppColors.violet;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(Corners.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: AppText.display(
          size: value >= 1000
              ? 18
              : value >= 100
                  ? 22
                  : 28,
          weight: FontWeight.w800,
          color: value <= 4 ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
    );
  }
}
