import 'skill_progress_model.dart';

class WeeklyReportModel {
  final String studentUid;
  final DateTime weekStartDate;
  final double overallAccuracyPercent;
  final int totalQuizzes;
  final Duration totalStudyTime;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<WeeklyAccuracyPoint> accuracyTrend;
  final List<SubjectTimeAllocation> subjectAllocations;
  final String aiInsightText;

  const WeeklyReportModel({
    required this.studentUid,
    required this.weekStartDate,
    required this.overallAccuracyPercent,
    required this.totalQuizzes,
    required this.totalStudyTime,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.accuracyTrend,
    required this.subjectAllocations,
    required this.aiInsightText,
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

class SubjectMasteryReport {
  final String subjectKey;
  final double totalMasteryPercent;
  final String masteryLabel;
  final List<SkillProgressModel> strongSkills;
  final List<SkillProgressModel> weakSkills;
  final ErrorAnalyticModel errorAnalytics;

  const SubjectMasteryReport({
    required this.subjectKey,
    required this.totalMasteryPercent,
    required this.masteryLabel,
    required this.strongSkills,
    required this.weakSkills,
    required this.errorAnalytics,
  });
}

class ErrorAnalyticModel {
  final double carelessPercent;
  final double conceptGapPercent;
  final double timePressurePercent;

  const ErrorAnalyticModel({
    required this.carelessPercent,
    required this.conceptGapPercent,
    required this.timePressurePercent,
  });
}

class StudyHabitsReport {
  final String studentUid;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<HeatmapDay> consistencyHeatmap;
  final List<StudyVsAppCorrelationPoint> correlation;

  const StudyHabitsReport({
    required this.studentUid,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.consistencyHeatmap,
    required this.correlation,
  });
}

class HeatmapDay {
  final DateTime date;
  final int studyMinutes;

  const HeatmapDay({
    required this.date,
    required this.studyMinutes,
  });
}

class StudyVsAppCorrelationPoint {
  final String dayLabel; // Mon, Tue, etc.
  final int studyMinutes;
  final int appUsageMinutes;

  const StudyVsAppCorrelationPoint({
    required this.dayLabel,
    required this.studyMinutes,
    required this.appUsageMinutes,
  });
}

class DailyStudentSnapshotModel {
  final String studentUid;
  final int quizzesCompletedToday;
  final Duration totalStudyTimeToday;
  final int averageAccuracyToday;

  const DailyStudentSnapshotModel({
    required this.studentUid,
    required this.quizzesCompletedToday,
    required this.totalStudyTimeToday,
    required this.averageAccuracyToday,
  });
}
