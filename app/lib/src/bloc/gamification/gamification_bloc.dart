// lib/src/bloc/gamification/gamification_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers/dataconnect_provider.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/models/gamification_models.dart';
import '../../services/student_local_notification_handler.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

// Mirrors the sets in StudentLocalNotificationHandler — kept here so the bloc
// can branch without importing private handler internals.
const _kStreakMilestones = {7, 14, 30};
const _kNearMilestones = {6, 13, 29};

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository repository;

  GamificationBloc({required this.repository}) : super(GamificationInitial()) {
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
      final profile = await repository.getStudentGamification(event.studentId);
      emit(GamificationLoaded(profile));
      await _cacheStreakState(event.studentId, profile.currentStreak);
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

        await _cacheStreakState(
          event.studentId,
          updated.currentStreak,
          quizCompleted: true,
        );

        final int? leveledUpTo = rewards['did_level_up'] == true
            ? rewards['new_level'] as int?
            : null;

        emit(
          GamificationRewardProcessed(
            profile: updated,
            xpEarned: rewards['xp_earned'] ?? 0,
            coinsEarned: rewards['coins_earned'] ?? 0,
            leveledUpTo: leveledUpTo,
            streakIncremented: rewards['streak_incremented'] == true,
            milestoneHit: rewards['milestone_hit'],
          ),
        );

        // Fire notifications after the state is emitted so the UI animation
        // and the notification land at the same time.
        if (leveledUpTo != null) {
          await StudentLocalNotificationHandler.instance.handleLevelUp(
            leveledUpTo,
          );
        }

        if (rewards['streak_incremented'] == true) {
          final streak = updated.currentStreak;
          if (_kStreakMilestones.contains(streak)) {
            await StudentLocalNotificationHandler.instance
                .handleStreakMilestone(streak);
          } else if (_kNearMilestones.contains(streak)) {
            await StudentLocalNotificationHandler.instance.handleNearMilestone(
              streak,
            );
          }
        }

        emit(GamificationLoaded(updated));
        return;
      }

      // Fallback if no rewards payload.
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
        emit(
          GamificationRewardProcessed(
            profile: result.updatedProfile,
            xpEarned: 0,
            coinsEarned: result.coinsEarned,
            leveledUpTo: null,
          ),
        );
        emit(GamificationLoaded(result.updatedProfile));
      }
    } catch (_) {}
  }

  /// Caches gamification state needed by `StreakReminderService.runTask`,
  /// which runs in a background isolate and cannot read this bloc's state.
  ///
  /// [quizCompleted] also stamps `last_active_at_{studentId}` with today's
  /// date so the reminder task can detect that a quiz was already taken
  /// today and skip the notification, and stamps `Student.lastActiveAt` on
  /// the server so the parent's inactivity check can do the same.
  Future<void> _cacheStreakState(
    String studentId,
    int currentStreak, {
    bool quizCompleted = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak_$studentId', currentStreak);
      if (quizCompleted) {
        await prefs.setString(
          'last_active_at_$studentId',
          DateTime.now().toIso8601String().split('T')[0],
        );
        try {
          await DataConnectProvider().updateStudentLastActiveAt();
        } catch (_) {
          // Best-effort — the parent's inactivity check will simply use a
          // stale lastActiveAt until the next successful quiz completion.
        }
      }
    } catch (_) {
      // Best-effort cache — a failure here must not affect the
      // gamification flow.
    }
  }
}
