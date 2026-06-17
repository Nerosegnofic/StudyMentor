import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'ai_summary_event.dart';
import 'ai_summary_state.dart';

class AiSummaryBloc extends Bloc<AiSummaryEvent, AiSummaryState> {
  final AuthRepository repository;

  AiSummaryBloc({required this.repository}) : super(AiSummaryInitial()) {
    on<LoadAiSummaryRequested>(_onLoadAiSummary);
  }

  Future<void> _onLoadAiSummary(
    LoadAiSummaryRequested event,
    Emitter<AiSummaryState> emit,
  ) async {
    emit(AiSummaryLoading());
    try {
      final summary = await repository.getAiSummary(event.children);
      emit(AiSummaryLoaded(summary));
    } catch (e) {
      emit(AiSummaryError('Failed to load AI summary: $e'));
    }
  }
}
