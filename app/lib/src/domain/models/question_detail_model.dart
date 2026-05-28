// lib/src/domain/models/question_detail_model.dart

class QuestionDetailModel {
  final String quizAttemptId;
  final int questionNumber;
  final bool isCorrect;
  final String questionText;
  final List<String> options;
  final String selectedAnswer;
  final String correctAnswer;

  const QuestionDetailModel({
    required this.quizAttemptId,
    required this.questionNumber,
    required this.isCorrect,
    required this.questionText,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
  });

  factory QuestionDetailModel.fromJson(Map<String, dynamic> json) {
    return QuestionDetailModel(
      quizAttemptId: json['quiz_attempt_id'] as String,
      questionNumber: json['question_number'] as int,
      isCorrect: json['is_correct'] as bool? ?? false,
      questionText: json['question_text'] as String,
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      selectedAnswer: json['selected_answer'] as String? ?? '',
      correctAnswer: json['correct_answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_attempt_id': quizAttemptId,
      'question_number': questionNumber,
      'is_correct': isCorrect,
      'question_text': questionText,
      'options': options,
      'selected_answer': selectedAnswer,
      'correct_answer': correctAnswer,
    };
  }
}
