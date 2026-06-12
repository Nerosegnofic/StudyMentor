import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/repositories/ai_engine_repository.dart';
import 'garden_event.dart';
import 'garden_state.dart';

class GardenBloc extends Bloc<GardenEvent, GardenState> {
  final AiEngineRepository _repo;

  GardenBloc({AiEngineRepository? repo})
      : _repo = repo ?? AiEngineRepository.instance,
        super(const GardenInitial()) {
    on<LoadGardenRequested>(_onLoad);
  }

  Future<void> _onLoad(
    LoadGardenRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(const GardenLoading());
    try {
      final plants = await _repo.getGarden();
      emit(GardenLoaded(plants: plants));
    } catch (e) {
      emit(GardenError(e.toString()));
    }
  }
}
