class SkillProgressModel {
  final String skillKey;
  final int correctAnswers;
  final int totalAttempts;
  final DateTime? lastPracticedAt;

  const SkillProgressModel({
    required this.skillKey,
    required this.correctAnswers,
    required this.totalAttempts,
    this.lastPracticedAt,
  });

  /// Mastery percentage: 0–100. Returns 0 if never attempted.
  double get masteryPercent {
    if (totalAttempts == 0) return 0.0;
    return (correctAnswers / totalAttempts) * 100.0;
  }
}
