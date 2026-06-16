import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/console/command_palette.dart';
import '../features/console/game_registry.dart';
import '../features/console/terminal_overlay.dart';
import '../state/console_cubit.dart';

/// Global shell mounted above the routed pages. Provides:
///   • Cmd-K / Ctrl-K → command palette
///   • Konami code (↑↑↓↓←→←→BA) via HardwareKeyboard — never steals focus
///   • Overlays: palette, terminal, game picker / game
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _konami = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];

  final List<LogicalKeyboardKey> _buf = [];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_konamiHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_konamiHandler);
    super.dispose();
  }

  bool _konamiHandler(KeyEvent e) {
    if (e is KeyDownEvent) {
      _buf.add(e.logicalKey);
      if (_buf.length > _konami.length) _buf.removeAt(0);
      if (_buf.length == _konami.length && _listEq(_buf, _konami)) {
        _buf.clear();
        if (mounted) context.read<ConsoleCubit>().openGame();
      }
    }
    return false; // never consume — games/fields keep their keys
  }

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            () => context.read<ConsoleCubit>().togglePalette(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            () => context.read<ConsoleCubit>().togglePalette(),
      },
      child: Focus(
        autofocus: true,
        child: BlocBuilder<ConsoleCubit, ConsoleState>(
          builder: (context, state) {
            final view = state.view;
            return Stack(
              children: [
                widget.child,
                if (view != ConsoleView.none)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => context.read<ConsoleCubit>().dismiss(),
                      child: const ColoredBox(color: Color(0x99000000)),
                    ),
                  ),
                if (view != ConsoleView.none)
                  Positioned.fill(
                    child: _OverlayBody(state: state),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverlayBody extends StatelessWidget {
  const _OverlayBody({required this.state});
  final ConsoleState state;

  @override
  Widget build(BuildContext context) {
    // Material is required by TextField inside the overlays.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {}, // absorb taps on the overlay itself
        behavior: HitTestBehavior.opaque,
        child: _buildView(context),
      ),
    );
  }

  Widget _buildView(BuildContext context) {
    final close = () => context.read<ConsoleCubit>().dismiss();
    switch (state.view) {
      case ConsoleView.palette:
        return const CommandPalette();
      case ConsoleView.terminal:
        return const TerminalOverlay();
      case ConsoleView.game:
        final gameId = state.gameId;
        if (gameId == null) return GamePicker(onClose: close);
        final entry = GameRegistry.byId(gameId);
        if (entry == null) return GamePicker(onClose: close);
        return entry.builder(close);
      case ConsoleView.none:
        return const SizedBox.shrink();
    }
  }
}
