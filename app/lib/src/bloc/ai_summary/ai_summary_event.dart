import 'package:equatable/equatable.dart';

abstract class AiSummaryEvent extends Equatable {
  const AiSummaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadAiSummaryRequested extends AiSummaryEvent {
  final String parentUid;

  const LoadAiSummaryRequested({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}
