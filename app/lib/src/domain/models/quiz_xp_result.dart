/// Holds the outcome of a completed quiz, used to update XP, level, and mastery.
class QuizXpResult {
  final String subjectKey;
  final String skillKey;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;

  /// 'easy' | 'medium' | 'hard'
  final String difficulty;

  /// Current streak days (from student profile)
  final int currentStreak;

  const QuizXpResult({
    required this.subjectKey,
    required this.skillKey,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.difficulty,
    required this.currentStreak,
  });

  bool get isPerfect => correctAnswers == totalQuestions && totalQuestions > 0;
}
