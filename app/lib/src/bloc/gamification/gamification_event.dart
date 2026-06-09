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
  final Map<String, dynamic>? rewards;

  const ProcessQuizRewardsRequested({
    required this.studentId,
    this.rewards,
  });

  @override
  List<Object?> get props => [studentId, rewards];
}

class CheckDailyLoginRewardRequested extends GamificationEvent {
  final String studentId;

  const CheckDailyLoginRewardRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}
