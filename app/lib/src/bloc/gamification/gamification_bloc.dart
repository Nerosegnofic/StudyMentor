import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/gamification_repository.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository repository;

  GamificationBloc({required this.repository})
      : super(GamificationInitial()) {
    on<LoadGamificationDataRequested>(_onLoadGamificationData);
    on<ProcessQuizRewardsRequested>(_onProcessQuizRewards);
    on<CheckDailyLoginRewardRequested>(_onCheckDailyLoginReward);
  }

  Future<void> _onLoadGamificationData(
    LoadGamificationDataRequested event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());
    try {
      final profile =
          await repository.getStudentGamification(event.studentId);
      emit(GamificationLoaded(profile));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  Future<void> _onProcessQuizRewards(
    ProcessQuizRewardsRequested event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final result = await repository.applyQuizRewards(
        studentId: event.studentId,
        score: event.score,
        totalQuestions: event.totalQuestions,
        timeTaken: event.timeTaken,
        context: event.context,
        isComeback: event.isComeback,
      );

      // 1. Emit transient reward state for UI toasts / level-up modals.
      emit(GamificationRewardProcessed(
        profile: result.updatedProfile,
        xpEarned: result.xpEarned,
        coinsEarned: result.coinsEarned,
        leveledUpTo: result.newLevel,
      ));

      // 2. Immediately settle into the steady-state so badges update.
      emit(GamificationLoaded(result.updatedProfile));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }

  Future<void> _onCheckDailyLoginReward(
    CheckDailyLoginRewardRequested event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final result = await repository.checkAndAwardDailyLogin(event.studentId);
      if (result != null) {
        emit(GamificationRewardProcessed(
          profile: result.updatedProfile,
          xpEarned: 0,
          coinsEarned: result.coinsEarned,
          leveledUpTo: null,
        ));
        emit(GamificationLoaded(result.updatedProfile));
      }
    } catch (_) {}
  }
}
