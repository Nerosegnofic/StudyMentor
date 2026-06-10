// lib/src/domain/models/gamification_enums.dart

/// Reasons a student can earn XP.
enum XpReason {
  correctAnswer,
  perfectQuizBonus,
  speedBonus,
  comebackBonus,
  persistenceBonus,
}

/// Reasons a student can earn Coins.
enum CoinReason {
  quizCompletion,
  dailyLogin,
  streakMilestone,
  freedomBonus,
}

/// The context in which a quiz was taken.
enum QuizContext {
  voluntary,
  forced,
}
