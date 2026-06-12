import 'package:equatable/equatable.dart';
import '../../domain/models/ai_summary_model.dart';

abstract class AiSummaryState extends Equatable {
  const AiSummaryState();

  @override
  List<Object?> get props => [];
}

class AiSummaryInitial extends AiSummaryState {}

class AiSummaryLoading extends AiSummaryState {}

class AiSummaryLoaded extends AiSummaryState {
  final AiSummaryModel summary;

  const AiSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class AiSummaryError extends AiSummaryState {
  final String message;

  const AiSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
