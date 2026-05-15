import '../domain/models/skill_progress_model.dart';

/// Pure-logic service for mastery analysis.
/// Does not talk to the database — operates on already-loaded [SkillProgressModel] lists.
class MasteryService {
  MasteryService._();

  /// Overall mastery percent for a subject (0–100).
  /// Computed as weighted average across all skills that have been attempted.
  static double overallMastery(List<SkillProgressModel> skills) {
    final attempted = skills.where((s) => s.totalAttempts > 0).toList();
    if (attempted.isEmpty) return 0.0;
    final totalCorrect = attempted.fold<int>(0, (sum, s) => sum + s.correctAnswers);
    final totalAttempts = attempted.fold<int>(0, (sum, s) => sum + s.totalAttempts);
    return (totalCorrect / totalAttempts) * 100.0;
  }

  /// Returns skills with mastery ≥ 75%, sorted strongest first.
  static List<SkillProgressModel> strongSkills(List<SkillProgressModel> skills) {
    return skills.where((s) => s.isStrong).toList()
      ..sort((a, b) => b.masteryPercent.compareTo(a.masteryPercent));
  }

  /// Returns skills with mastery < 50% and at least 1 attempt, sorted weakest first.
  static List<SkillProgressModel> weakSkills(List<SkillProgressModel> skills) {
    return skills.where((s) => s.isWeak).toList()
      ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
  }

  /// Returns skills never attempted.
  static List<SkillProgressModel> untouchedSkills(List<SkillProgressModel> skills) {
    return skills.where((s) => s.totalAttempts == 0).toList();
  }

  /// Merges an existing skill record with quiz results.
  static SkillProgressModel mergeResult({
    required SkillProgressModel existing,
    required int correctAnswers,
    required int wrongAnswers,
  }) {
    return existing.copyWith(
      correctAnswers: existing.correctAnswers + correctAnswers,
      wrongAnswers: existing.wrongAnswers + wrongAnswers,
      totalAttempts: existing.totalAttempts + correctAnswers + wrongAnswers,
      lastPracticedAt: DateTime.now(),
    );
  }

  /// Mastery tier label for display.
  static String masteryLabel(double percent) {
    if (percent >= 90) return 'Expert';
    if (percent >= 75) return 'Strong';
    if (percent >= 50) return 'Developing';
    if (percent > 0) return 'Needs Practice';
    return 'Not Started';
  }
}
