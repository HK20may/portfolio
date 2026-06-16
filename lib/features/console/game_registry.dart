import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../state/console_cubit.dart';
import 'games/asteroids_game.dart';
import 'games/g2048.dart';
import 'games/physics_sandbox.dart';
import 'games/snake_game.dart';
import 'mini_game.dart';

typedef GameBuilder = Widget Function(VoidCallback onClose);

class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.builder,
  });
  final String id, title, blurb;
  final IconData icon;
  final GameBuilder builder;
}

class GameRegistry {
  static final List<GameEntry> games = [
    GameEntry(
      id: 'breakout',
      title: 'Breakout',
      blurb: 'Classic brick-breaker — paddle + ball physics.',
      icon: Icons.sports_cricket_rounded,
      builder: (onClose) => MiniGame(onClose: onClose),
    ),
    GameEntry(
      id: 'snake',
      title: 'Snake',
      blurb: 'Grid + game loop — eat, grow, don\'t bite yourself.',
      icon: Icons.linear_scale_rounded,
      builder: (onClose) => SnakeGame(onClose: onClose),
    ),
    GameEntry(
      id: '2048',
      title: '2048',
      blurb: 'Gestures + animated merges — reach the tile.',
      icon: Icons.grid_4x4_rounded,
      builder: (onClose) => G2048(onClose: onClose),
    ),
    GameEntry(
      id: 'asteroids',
      title: 'Asteroids',
      blurb: 'Vector physics + screen wrap — rotate, thrust, fire.',
      icon: Icons.rocket_launch_outlined,
      builder: (onClose) => AsteroidsGame(onClose: onClose),
    ),
    GameEntry(
      id: 'sandbox',
      title: 'Sandbox',
      blurb: 'Real-time physics + gestures — spawn, bounce, fling.',
      icon: Icons.bubble_chart_outlined,
      builder: (onClose) => PhysicsSandbox(onClose: onClose),
    ),
  ];

  static GameEntry? byId(String id) {
    for (final g in games) {
      if (g.id == id) return g;
    }
    return null;
  }
}

/// Shown when `gameId == null` — a grid of available games.
class GamePicker extends StatelessWidget {
  const GamePicker({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final w = context.responsive<double>(mobile: double.infinity, tablet: 440, desktop: 480);
    final games = GameRegistry.games;

    return Center(
      child: SizedBox(
        width: w == double.infinity
            ? MediaQuery.sizeOf(context).width - context.pageGutter * 2
            : w,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corners.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(Corners.lg),
                border: Border.all(color: AppColors.borderStrong),
              ),
              padding: const EdgeInsets.all(Insets.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Choose a game',
                          style: AppText.display(size: 20, weight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textTertiary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),
                  for (final g in games)
                    _GameCard(entry: g, onClose: onClose),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({required this.entry, required this.onClose});
  final GameEntry entry;
  final VoidCallback onClose;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.read<ConsoleCubit>().openGame(widget.entry.id),
        child: AnimatedContainer(
          duration: Motion.fast,
          margin: const EdgeInsets.only(bottom: Insets.sm),
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.violet.withValues(alpha: 0.15)
                : AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(
              color: _hover ? AppColors.violet.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.entry.icon,
                  size: 28,
                  color: _hover ? AppColors.violet : AppColors.textSecondary),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.entry.title,
                        style: AppText.display(size: 18, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.entry.blurb,
                        style: AppText.mono(
                            size: 12, color: AppColors.textTertiary, spacing: 0.3)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
