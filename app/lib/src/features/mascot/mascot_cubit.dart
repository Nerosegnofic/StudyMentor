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

  void startThinking() => emit(MascotState.thinking);

  void react(bool correct) =>
      emit(correct ? MascotState.happy : MascotState.sad);
}
