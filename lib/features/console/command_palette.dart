import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/router.dart';
import '../../core/data/portfolio_data.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launch.dart';
import '../../state/console_cubit.dart';
import '../../state/navigation_cubit.dart';
import '../../state/palette_cubit.dart';
import '../../state/scroll_intent_cubit.dart';

class _Command {
  const _Command({
    required this.icon,
    required this.label,
    this.hint,
    required this.action,
  });
  final IconData icon;
  final String label;
  final String? hint;
  final void Function(BuildContext) action;
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _selected = 0;

  late final List<_Command> _allCommands;

  // Intercepts Esc/arrows/Enter before the TextField sees them so those keys
  // work even while typing (arrow navigation, Esc-to-close, Enter-to-run).
  late final FocusNode _searchFocus = FocusNode(
    debugLabel: 'palette-search',
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final k = event.logicalKey;
      if (k == LogicalKeyboardKey.escape) {
        context.read<ConsoleCubit>().dismiss();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.arrowDown) {
        _move(1);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.arrowUp) {
        _move(-1);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
        final list = _filtered;
        if (list.isNotEmpty) list[_selected].action(context);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );

  bool _commandsBuilt = false;

  @override
  void initState() {
    super.initState();
    // Explicitly steal focus after the first frame so the TextField wins even
    // when AppShell's Focus(autofocus:true) already holds it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_commandsBuilt) {
      _commandsBuilt = true;
      _allCommands = _buildCommands(context);
    }
  }

  List<_Command> _buildCommands(BuildContext ctx) {
    final socials = PortfolioData.profile.socials;

    void navTo(Section s) {
      ctx.read<ScrollIntentCubit>().request(s);
      appRouter.go('/');
      ctx.read<ConsoleCubit>().dismiss();
    }

    return [
      _Command(icon: Icons.home_rounded, label: 'Home', hint: 'Navigate', action: (_) => navTo(Section.hero)),
      _Command(icon: Icons.person_outline_rounded, label: 'About', hint: 'Navigate', action: (_) => navTo(Section.about)),
      _Command(icon: Icons.code_rounded, label: 'Skills', hint: 'Navigate', action: (_) => navTo(Section.skills)),
      _Command(icon: Icons.work_outline_rounded, label: 'Work', hint: 'Navigate', action: (_) => navTo(Section.work)),
      _Command(icon: Icons.history_edu_rounded, label: 'Experience', hint: 'Navigate', action: (_) => navTo(Section.experience)),
      _Command(icon: Icons.mail_outline_rounded, label: 'Contact', hint: 'Navigate', action: (_) => navTo(Section.contact)),
      _Command(icon: Icons.science_outlined, label: 'Open Lab', hint: 'Route', action: (c) { appRouter.go('/lab'); c.read<ConsoleCubit>().dismiss(); }),
      _Command(icon: Icons.terminal_rounded, label: 'Open Terminal', hint: 'Dev tools', action: (c) => c.read<ConsoleCubit>().openTerminal()),
      _Command(icon: Icons.sports_esports_outlined, label: 'Play a game', hint: 'Dev tools', action: (c) => c.read<ConsoleCubit>().openGame()),
      _Command(icon: Icons.auto_awesome_rounded, label: 'Toggle Vivid mode', hint: 'Theme', action: (c) { c.read<PaletteCubit>().toggle(); c.read<ConsoleCubit>().dismiss(); }),
      for (final s in socials)
        _Command(
          icon: _socialIcon(s.label),
          label: s.label,
          hint: 'Social',
          action: (_) { openUrl(s.url); ctx.read<ConsoleCubit>().dismiss(); },
        ),
    ];
  }

  IconData _socialIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('github')) return Icons.code;
    if (l.contains('linkedin')) return Icons.business_center_outlined;
    if (l.contains('twitter') || l.contains('x')) return Icons.tag;
    if (l.contains('email')) return Icons.mail_outline_rounded;
    return Icons.link;
  }

  List<_Command> get _filtered {
    if (_query.isEmpty) return _allCommands;
    final q = _query.toLowerCase();
    return _allCommands.where((c) => c.label.toLowerCase().contains(q)).toList();
  }

  void _run(int index, BuildContext ctx) {
    final list = _filtered;
    if (index < 0 || index >= list.length) return;
    list[index].action(ctx);
  }

  void _move(int delta) {
    final list = _filtered;
    if (list.isEmpty) return;
    final next = (_selected + delta).clamp(0, list.length - 1);
    setState(() => _selected = next);
    _scrollToSelected(next);
  }

  void _scrollToSelected(int index) {
    const itemH = 52.0;
    final offset = (index * itemH).clamp(
      0.0,
      _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0,
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final width = context.responsive<double>(mobile: double.infinity, tablet: 560, desktop: 600);

    return Center(
      child: SizedBox(
          width: width == double.infinity
              ? MediaQuery.sizeOf(context).width - context.pageGutter * 2
              : width,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                          const SizedBox(width: Insets.sm),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _searchFocus,
                              autofocus: true,
                              style: AppText.mono(size: 15, color: AppColors.textPrimary, spacing: 0),
                              decoration: InputDecoration(
                                hintText: 'Type a command…',
                                hintStyle: AppText.mono(size: 15, color: AppColors.textTertiary, spacing: 0),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() { _query = v; _selected = 0; }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    Container(height: 1, color: AppColors.border),
                    // Results
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: list.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(Insets.xl),
                              child: Text('No results for "$_query"',
                                  style: AppText.body(color: AppColors.textTertiary)),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              itemCount: list.length,
                              itemExtent: 52,
                              itemBuilder: (ctx, i) {
                                final cmd = list[i];
                                final active = i == _selected;
                                return MouseRegion(
                                  onEnter: (_) => setState(() => _selected = i),
                                  child: GestureDetector(
                                    onTap: () => _run(i, context),
                                    child: AnimatedContainer(
                                      duration: Motion.fast,
                                      color: active
                                          ? AppColors.violet.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: Insets.lg, vertical: 0),
                                      child: Row(
                                        children: [
                                          Icon(cmd.icon,
                                              size: 18,
                                              color: active
                                                  ? AppColors.violet
                                                  : AppColors.textTertiary),
                                          const SizedBox(width: Insets.md),
                                          Expanded(
                                            child: Text(
                                              cmd.label,
                                              style: AppText.body(
                                                size: 15,
                                                weight: FontWeight.w500,
                                                color: active
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (cmd.hint != null)
                                            Text(cmd.hint!,
                                                style: AppText.mono(
                                                    size: 11,
                                                    color: AppColors.textTertiary,
                                                    spacing: 0.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(height: 1, color: AppColors.border),
                    // Footer legend
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.lg, vertical: 10),
                      child: Row(
                        children: [
                          _Legend('↑↓', 'navigate'),
                          const SizedBox(width: Insets.lg),
                          _Legend('↵', 'select'),
                          const SizedBox(width: Insets.lg),
                          _Legend('esc', 'close'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.key_, this.action);
  final String key_;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(key_, style: AppText.mono(size: 11, color: AppColors.textSecondary, spacing: 0)),
        ),
        const SizedBox(width: 6),
        Text(action, style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0)),
      ],
    );
  }
}
