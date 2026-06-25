class WeeklyReportModel {
  final double overallAccuracyPercent;
  final int totalQuizzes;
  final Duration totalStudyTime;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<WeeklyAccuracyPoint> accuracyTrend;
  final List<SubjectTimeAllocation> subjectAllocations;
  final String aiInsightText;

  /// Effort & focus signals (this week).
  final int voluntaryQuizzes;
  final int forcedQuizzes;
  final int guessingSessions;

  /// Week-over-week deltas. `accuracyDelta` is null when there's no prior-week
  /// baseline (last week had no quizzes), so the UI can omit it.
  final double? accuracyDelta;
  final int studyMinutesDelta;
  final int quizzesDelta;

  /// Prioritized "needs attention" alerts (highest severity first).
  final List<AlertModel> alerts;

  const WeeklyReportModel({
    required this.overallAccuracyPercent,
    required this.totalQuizzes,
    required this.totalStudyTime,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.accuracyTrend,
    required this.subjectAllocations,
    required this.aiInsightText,
    this.voluntaryQuizzes = 0,
    this.forcedQuizzes = 0,
    this.guessingSessions = 0,
    this.accuracyDelta,
    this.studyMinutesDelta = 0,
    this.quizzesDelta = 0,
    this.alerts = const [],
  });
}

/// A single "needs attention" alert. `severity` is "high" | "medium" | "info".
class AlertModel {
  final String severity;
  final String message;

  const AlertModel({
    required this.severity,
    required this.message,
  });
}

class WeeklyAccuracyPoint {
  final String weekLabel;
  final double accuracy;

  const WeeklyAccuracyPoint({
    required this.weekLabel,
    required this.accuracy,
  });
}

class SubjectTimeAllocation {
  final String subjectKey;
  final double percentage;
  final String colorHex;

  const SubjectTimeAllocation({
    required this.subjectKey,
    required this.percentage,
    required this.colorHex,
  });
}

/// A selectable subject in the Mastery tab's chip row.
class SubjectChipModel {
  final int id;
  final String name;

  const SubjectChipModel({required this.id, required this.name});
}

/// A single skill row in the Mastery tab (Strong / Needs-Work lists).
/// `masteryPercent` is the BKT mastery probability (0–100), not an answer ratio.
class MasterySkill {
  final String name;
  final double masteryPercent;

  const MasterySkill({required this.name, required this.masteryPercent});
}

class SubjectMasteryReport {
  final String subjectKey;
  final double totalMasteryPercent;
  final String masteryLabel;
  final List<MasterySkill> strongSkills;
  final List<MasterySkill> weakSkills;

  /// Null when there are no graded answers yet; the UI hides the Error Analytics
  /// card while this is null rather than show an empty breakdown.
  final ErrorAnalyticModel? errorAnalytics;

  /// Accuracy per question difficulty band (1–5). Empty when no answers yet.
  final List<DifficultyAccuracy> difficultyAccuracy;

  /// Daily mastery snapshots (oldest first). Empty until snapshots accumulate.
  final List<MasteryHistoryPoint> masteryHistory;

  const SubjectMasteryReport({
    required this.subjectKey,
    required this.totalMasteryPercent,
    required this.masteryLabel,
    required this.strongSkills,
    required this.weakSkills,
    this.errorAnalytics,
    this.difficultyAccuracy = const [],
    this.masteryHistory = const [],
  });
}

/// A single daily mastery reading for the mastery-over-time chart.
class MasteryHistoryPoint {
  final double mastery; // 0–100

  const MasteryHistoryPoint({required this.mastery});
}

/// Mistake-type split for wrong answers. Quizzes are untimed, so there is no
/// "time pressure" category — only careless, concept-gap, and guessing.
class ErrorAnalyticModel {
  final double carelessPercent;
  final double conceptGapPercent;
  final double guessingPercent;

  const ErrorAnalyticModel({
    required this.carelessPercent,
    required this.conceptGapPercent,
    required this.guessingPercent,
  });
}

/// Accuracy for a single question-difficulty band (1 = easiest … 5 = hardest).
class DifficultyAccuracy {
  final int difficulty;
  final int total;
  final double accuracy;

  const DifficultyAccuracy({
    required this.difficulty,
    required this.total,
    required this.accuracy,
  });
}

class StudyHabitsReport {
  final int currentStreakDays;
  final int longestStreakDays;
  final List<HeatmapDay> consistencyHeatmap;
  final List<DailyStudyPoint> dailyStudy;
  final List<TimeOfDayPoint> timeOfDay;

  const StudyHabitsReport({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.consistencyHeatmap,
    required this.dailyStudy,
    this.timeOfDay = const [],
  });
}

/// Study minutes in a part of the day (Morning / Afternoon / Evening / Night).
class TimeOfDayPoint {
  final String label;
  final int minutes;

  const TimeOfDayPoint({required this.label, required this.minutes});
}

class HeatmapDay {
  final int studyMinutes;

  const HeatmapDay({required this.studyMinutes});
}

/// Study minutes for a single recent day, for the Habits daily-study chart.
class DailyStudyPoint {
  final String dayLabel; // Mon, Tue, etc.
  final int studyMinutes;

  const DailyStudyPoint({
    required this.dayLabel,
    required this.studyMinutes,
  });
}

class DailyStudentSnapshotModel {
  final int quizzesCompletedToday;
  final Duration totalStudyTimeToday;
  final int averageAccuracyToday;

  /// Per-subject breakdown of today's questions, highest first.
  final List<SubjectQuestionCount> questionsBySubject;

  const DailyStudentSnapshotModel({
    required this.quizzesCompletedToday,
    required this.totalStudyTimeToday,
    required this.averageAccuracyToday,
    this.questionsBySubject = const [],
  });
}

/// One subject's share of today's answered questions (for the home ring).
class SubjectQuestionCount {
  final String subjectName;
  final int questions;

  const SubjectQuestionCount({
    required this.subjectName,
    required this.questions,
  });

  factory SubjectQuestionCount.fromJson(Map<String, dynamic> json) =>
      SubjectQuestionCount(
        subjectName: (json['subject_name'] as String?) ?? 'General',
        questions: (json['questions'] as int?) ?? 0,
      );
}
