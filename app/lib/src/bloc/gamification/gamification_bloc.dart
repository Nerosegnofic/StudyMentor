import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/models/gamification_models.dart';
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
      final rewards = event.rewards;
      if (rewards != null) {
        // We know exactly what was earned and the new totals!
        final updated = StudentGamificationModel(
          studentId: event.studentId,
          xpTotal: rewards['xp_total'] ?? 0,
          coinsTotal: rewards['coins_total'] ?? 0,
          currentLevel: rewards['new_level'] ?? 1,
          currentStreak: rewards['current_streak'] ?? 0,
          longestStreak: rewards['longest_streak'] ?? 0,
          lastQuizDate: rewards['last_quiz_date'],
          nextMilestone: rewards['next_milestone'],
          nextMilestoneDaysAway: rewards['next_milestone_days_away'],
        );
        emit(GamificationRewardProcessed(
          profile: updated,
          xpEarned: rewards['xp_earned'] ?? 0,
          coinsEarned: rewards['coins_earned'] ?? 0,
          leveledUpTo: rewards['did_level_up'] == true ? rewards['new_level'] : null,
          streakIncremented: rewards['streak_incremented'] == true,
          milestoneHit: rewards['milestone_hit'],
        ));
        emit(GamificationLoaded(updated));
        return;
      }

      // Fallback if no rewards payload
      final profile = await repository.getStudentGamification(event.studentId);
      emit(GamificationLoaded(profile));
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
