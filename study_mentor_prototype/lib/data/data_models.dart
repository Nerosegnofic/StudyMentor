enum UserRole {
  parent,
  child,
}

// Represents the tags for a single question
class Tags {
  final String subject;
  final String grade;
  final String topic;
  final int difficulty;

  Tags({
    required this.subject,
    required this.grade,
    required this.topic,
    required this.difficulty,
  });

  factory Tags.fromJson(Map<String, dynamic> json) {
    return Tags(
      subject: json['subject'],
      grade: json['grade'],
      topic: json['topic'],
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'grade': grade,
      'topic': topic,
      'difficulty': difficulty,
    };
  }
}

// Represents a single question in a quiz
class Question {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final Tags tags;

  Question({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      questionText: json['questionText'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'],
      explanation: json['explanation'],
      tags: Tags.fromJson(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'tags': tags.toJson(),
    };
  }
}

// Represents the result of a single quiz
class QuizResult {
  final String quizId;
  final List<Question> questions;

  QuizResult({
    required this.quizId,
    required this.questions,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    var questionList = (json['questions'] as List)
        .map((qJson) => Question.fromJson(qJson))
        .toList();

    return QuizResult(
      quizId: json['quizId'],
      questions: questionList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

// Represents the configuration for a child user
class ChildConfig {
  final int grade;
  final List<String> subjects;
  final int sessionTimeMinutes;

  ChildConfig({
    required this.grade,
    required this.subjects,
    required this.sessionTimeMinutes,
  });

  factory ChildConfig.fromJson(Map<String, dynamic> json) {
    return ChildConfig(
      grade: json['grade'],
      subjects: List<String>.from(json['subjects']),
      sessionTimeMinutes: json['session_time_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'subjects': subjects,
      'session_time_minutes': sessionTimeMinutes,
    };
  }
}

// Represents the Strengths & Weaknesses analysis
class Analysis {
  final List<String> strengths;
  final List<String> weaknesses;

  Analysis({required this.strengths, required this.weaknesses});

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }
}

// A plain, non-abstract User class for composition
class User {
  final String id;
  final String username;
  final String password;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
  });
}

// The Parent data model
class Parent {
  final User userInfo;
  final List<String> childrenIds;

  Parent({required this.userInfo, required this.childrenIds});

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      userInfo: User(
        id: json['id'],
        username: json['username'],
        password: json['password'],
        role: UserRole.parent,
      ),
      childrenIds: List<String>.from(json['children_ids']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userInfo.id,
      'username': userInfo.username,
      'password': userInfo.password,
      'role': userInfo.role.name,
      'children_ids': childrenIds,
    };
  }
}

// The Child data model
class Child {
  final User userInfo;
  final ChildConfig config;
  final List<QuizResult> quizzes;
  final Analysis analysis;

  Child({
    required this.userInfo,
    required this.config,
    required this.quizzes,
    required this.analysis,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    var quizList = (json['quizzes'] as List)
        .map((quizJson) => QuizResult.fromJson(quizJson))
        .toList();

    return Child(
      userInfo: User(
        id: json['id'],
        username: json['username'],
        password: json['password'],
        role: UserRole.child,
      ),
      config: ChildConfig.fromJson(json['config']),
      quizzes: quizList,
      analysis: Analysis.fromJson(json['analysis']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userInfo.id,
      'username': userInfo.username,
      'password': userInfo.password,
      'role': userInfo.role.name,
      'config': config.toJson(),
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
      'analysis': analysis.toJson(),
    };
  }
}