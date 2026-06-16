import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Gives a game its own focused input: a FocusNode that grabs focus on open,
/// plus a live set of currently-held keys so movement can be applied per tick.
mixin GameKeyboard<T extends StatefulWidget> on State<T> {
  final FocusNode gameFocus = FocusNode(debugLabel: 'game');
  final Set<LogicalKeyboardKey> heldKeys = <LogicalKeyboardKey>{};

  void initGameKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) gameFocus.requestFocus();
    });
  }

  KeyEventResult handleGameKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      heldKeys.add(event.logicalKey);
      onGameKeyDown(event.logicalKey);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      heldKeys.remove(event.logicalKey);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Override for one-shot keypress actions (start, restart, escape, etc.).
  void onGameKeyDown(LogicalKeyboardKey key) {}

  void disposeGameKeyboard() => gameFocus.dispose();
}
