import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_cubit.dart';

class ScrollIntentCubit extends Cubit<Section?> {
  ScrollIntentCubit() : super(null);
  void request(Section s) => emit(s);
  void clear() => emit(null);
}
