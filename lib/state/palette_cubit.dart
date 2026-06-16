import 'package:flutter_bloc/flutter_bloc.dart';

enum Palette { calm, vivid }

class PaletteCubit extends Cubit<Palette> {
  PaletteCubit() : super(Palette.calm);
  void toggle() => emit(state == Palette.vivid ? Palette.calm : Palette.vivid);
  void set(Palette p) => emit(p);
  bool get isVivid => state == Palette.vivid;
}
