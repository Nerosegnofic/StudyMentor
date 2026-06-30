class SkillProgressModel {
  final String studentUid;
  final String subjectKey;
  final String skillKey;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalAttempts;
  final DateTime? lastPracticedAt;

  const SkillProgressModel({
    required this.studentUid,
    required this.subjectKey,
    required this.skillKey,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalAttempts,
    this.lastPracticedAt,
  });

  /// Mastery percentage: 0–100. Returns 0 if never attempted.
  double get masteryPercent {
    if (totalAttempts == 0) return 0.0;
    return (correctAnswers / totalAttempts) * 100.0;
  }

  bool get isStrong => masteryPercent >= 75;
  bool get isWeak => totalAttempts > 0 && masteryPercent < 50;

  SkillProgressModel copyWith({
    int? correctAnswers,
    int? wrongAnswers,
    int? totalAttempts,
    DateTime? lastPracticedAt,
  }) {
    return SkillProgressModel(
      studentUid: studentUid,
      subjectKey: subjectKey,
      skillKey: skillKey,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }

  static SkillProgressModel empty({
    required String studentUid,
    required String subjectKey,
    required String skillKey,
  }) {
    return SkillProgressModel(
      studentUid: studentUid,
      subjectKey: subjectKey,
      skillKey: skillKey,
      correctAnswers: 0,
      wrongAnswers: 0,
      totalAttempts: 0,
    );
  }
}
