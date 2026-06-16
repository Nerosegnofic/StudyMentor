import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';

abstract class AiSummaryEvent extends Equatable {
  const AiSummaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadAiSummaryRequested extends AiSummaryEvent {
  final List<StudentModel> children;

  const LoadAiSummaryRequested({required this.children});

  @override
  List<Object?> get props => [children];
}
