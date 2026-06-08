import 'package:equatable/equatable.dart';
import '../../domain/models/gamification_enums.dart';

abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadGamificationDataRequested extends GamificationEvent {
  final String studentId;

  const LoadGamificationDataRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class ProcessQuizRewardsRequested extends GamificationEvent {
  final String studentId;
  final int score;
  final int totalQuestions;
  final Duration timeTaken;
  final QuizContext context;
  final bool isComeback;

  const ProcessQuizRewardsRequested({
    required this.studentId,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.context,
    required this.isComeback,
  });

  @override
  List<Object?> get props => [
        studentId,
        score,
        totalQuestions,
        timeTaken,
        context,
        isComeback,
      ];
}

class CheckDailyLoginRewardRequested extends GamificationEvent {
  final String studentId;

  const CheckDailyLoginRewardRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}
