import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'snapshot_event.dart';
import 'snapshot_state.dart';

class SnapshotBloc extends Bloc<SnapshotEvent, SnapshotState> {
  final AuthRepository repository;

  SnapshotBloc({required this.repository}) : super(SnapshotInitial()) {
    on<LoadDailySnapshotRequested>(_onLoadDailySnapshot);
  }

  Future<void> _onLoadDailySnapshot(
    LoadDailySnapshotRequested event,
    Emitter<SnapshotState> emit,
  ) async {
    emit(SnapshotLoading());
    try {
      final snapshot = await repository.getDailySnapshot(event.studentUid);
      emit(SnapshotLoaded(snapshot));
    } catch (e) {
      emit(SnapshotError('Failed to load snapshot: $e'));
    }
  }
}
