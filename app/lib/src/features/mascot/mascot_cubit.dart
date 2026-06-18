import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'mascot_state.dart';

/// Drives the mascot's current emotional state.
///
/// Does NOT subscribe to other BLoCs in its constructor — individual
/// screens/widgets call these named helpers when their own BLoC state
/// changes. This keeps dependencies explicit instead of a tangled listener
/// web.
class MascotCubit extends Cubit<MascotState> {
  MascotCubit() : super(MascotState.idle);

  Timer? _revertTimer;

  void rest() => emit(MascotState.idle);

  void startThinking() => emit(MascotState.thinking);

  void react(bool correct) =>
      emit(correct ? MascotState.happy : MascotState.sad);

  void celebrate() => emit(MascotState.celebration);

  void showHappy() => emit(MascotState.happy);

  void showSad() => emit(MascotState.sad);

  /// Emits [state] immediately, then reverts to [MascotState.idle] after
  /// [duration]. Cancels any previously pending revert first, so rapid
  /// calls (e.g. answering quiz questions quickly) never stack up timers.
  void reactTemporarily(
    MascotState state, {
    Duration duration = const Duration(milliseconds: 800),
  }) {
    _revertTimer?.cancel();
    emit(state);
    _revertTimer = Timer(duration, () {
      if (!isClosed) emit(MascotState.idle);
    });
  }

  @override
  Future<void> close() {
    _revertTimer?.cancel();
    return super.close();
  }
}
