import 'package:flutter_bloc/flutter_bloc.dart';

enum ConsoleView { none, palette, terminal, game }

class ConsoleState {
  const ConsoleState(this.view, {this.gameId});
  final ConsoleView view;
  final String? gameId; // null → show the game picker
  ConsoleState copyWith({ConsoleView? view, String? gameId}) =>
      ConsoleState(view ?? this.view, gameId: gameId);
}

class ConsoleCubit extends Cubit<ConsoleState> {
  ConsoleCubit() : super(const ConsoleState(ConsoleView.none));
  void togglePalette() => emit(ConsoleState(
      state.view == ConsoleView.palette ? ConsoleView.none : ConsoleView.palette));
  void openTerminal() => emit(const ConsoleState(ConsoleView.terminal));
  void openGame([String? gameId]) =>
      emit(ConsoleState(ConsoleView.game, gameId: gameId));
  void dismiss() => emit(const ConsoleState(ConsoleView.none));
}
