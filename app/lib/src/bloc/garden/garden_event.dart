import 'package:equatable/equatable.dart';
import '../../domain/models/quiz_xp_result.dart';

abstract class GardenEvent extends Equatable {
  const GardenEvent();
  @override
  List<Object?> get props => [];
}

/// Load all subject progress for [studentUid].
class LoadGardenRequested extends GardenEvent {
  final String studentUid;
  const LoadGardenRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

/// Load skills for a specific subject (used on the detail page).
class LoadSubjectSkillsRequested extends GardenEvent {
  final String studentUid;
  final String subjectKey;
  const LoadSubjectSkillsRequested({required this.studentUid, required this.subjectKey});
  @override
  List<Object?> get props => [studentUid, subjectKey];
}

/// Called when a quiz finishes — triggers XP + mastery updates.
class QuizCompletedForSubject extends GardenEvent {
  final String studentUid;
  final QuizXpResult result;
  const QuizCompletedForSubject({required this.studentUid, required this.result});
  @override
  List<Object?> get props => [studentUid, result.subjectKey, result.skillKey];
}
