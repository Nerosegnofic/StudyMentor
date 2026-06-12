import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../catalog/document_models.dart';
import '../../domain/models/garden_plant_model.dart';
import '../../domain/models/skill_detail_model.dart';

// ---------------------------------------------------------------------------
// Quiz DTOs (mirrors ai_engine/app/models/schemas/quiz_schemas.py)
// ---------------------------------------------------------------------------

class GenerateQuizRequest {
  final int? subjectId;
  final int totalQuestions;
  final int studentGrade;

  const GenerateQuizRequest({
    this.subjectId,
    required this.totalQuestions,
    this.studentGrade = 5,
  });

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'total_questions': totalQuestions,
        'student_grade': studentGrade,
      };
}

class QuestionModel {
  final String questionId;
  final String topic;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int difficulty;
  final List<String> hints;

  const QuestionModel({
    required this.questionId,
    required this.topic,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.hints,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['question_id'] as String,
      topic: json['topic'] as String,
      questionText: json['question_text'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as int,
      hints: List<String>.from(json['hints'] as List),
    );
  }
}

class GenerateQuizResponse {
  final String quizSessionId;
  final int selectedSubjectId;
  final String selectedSubjectName;
  final String quizTitle;
  final List<QuestionModel> questions;

  const GenerateQuizResponse({
    required this.quizSessionId,
    required this.selectedSubjectId,
    required this.selectedSubjectName,
    required this.quizTitle,
    required this.questions,
  });

  factory GenerateQuizResponse.fromJson(Map<String, dynamic> json) {
    return GenerateQuizResponse(
      quizSessionId: json['quiz_session_id'] as String,
      selectedSubjectId: json['selected_subject_id'] as int,
      selectedSubjectName: json['selected_subject_name'] as String,
      quizTitle: json['quiz_title'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAnswer {
  final String questionId;
  final String selectedOption;
  final int timeTakenMs;
  final int hintsUsed;

  const StudentAnswer({
    required this.questionId,
    required this.selectedOption,
    required this.timeTakenMs,
    required this.hintsUsed,
  });

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'selected_option': selectedOption,
        'time_taken_ms': timeTakenMs,
        'hints_used': hintsUsed,
      };
}

class QuizSubmissionRequest {
  final String quizSessionId;
  final List<StudentAnswer> answers;
  final String clientLocalDate;

  const QuizSubmissionRequest({
    required this.quizSessionId,
    required this.answers,
    required this.clientLocalDate,
  });

  Map<String, dynamic> toJson() => {
        'quiz_session_id': quizSessionId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'client_local_date': clientLocalDate,
      };
}

class QuizSubmissionResponse {
  final double score;
  final int totalQuestions;
  final String feedback;
  final Map<String, dynamic>? rewards;

  const QuizSubmissionResponse({
    required this.score,
    required this.totalQuestions,
    required this.feedback,
    this.rewards,
  });

  factory QuizSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionResponse(
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['total_questions'] as int,
      feedback: json['feedback'] as String,
      rewards: json['rewards'] as Map<String, dynamic>?,
    );
  }
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Centralised HTTP client for all AI Engine endpoints.
///
/// Every method automatically attaches the Firebase JWT obtained from the
/// currently signed-in user.  If no user is logged in an [Exception] is
/// thrown before any network request is made.
///
/// Usage:
/// ```dart
/// final quiz = await AiEngineRepository.instance
///     .generateQuiz(GenerateQuizRequest(totalQuestions: 5));
/// ```
class AiEngineRepository {
  /// Base URL of the AI Engine.
  /// - Android emulator → `http://10.0.2.2:8000`
  /// - iOS simulator   → `http://127.0.0.1:8000`
  /// - Physical device → your machine's LAN IP, e.g. `http://192.168.x.x:8000`
  ///
  /// Change this single constant when switching environments.
  static const String defaultBaseUrl = 'http://192.168.1.6:8000';

  /// Lazy singleton — created on first access, reused everywhere.
  static final AiEngineRepository instance = AiEngineRepository(
    baseUrl: defaultBaseUrl,
  );

  final String baseUrl;
  final FirebaseAuth _auth;

  AiEngineRepository({
    required this.baseUrl,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Returns JSON headers with a fresh Firebase Bearer token.
  Future<Map<String, String>> _getJsonHeaders() async {
    final token = await _requireToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Returns the raw Bearer token string.
  Future<String> _requireToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not authenticated.');
    // force: false — use cached token unless it has less than 5 min left.
    final token = await user.getIdToken(false);
    if (token == null) throw Exception('Unable to retrieve Firebase ID token.');
    return token;
  }

  void _assertSuccess(http.Response response, String context) {
    if (response.statusCode != 200) {
      throw Exception('$context failed [${response.statusCode}]: ${response.body}');
    }
  }

  // -------------------------------------------------------------------------
  // Quiz endpoints
  // -------------------------------------------------------------------------

  /// `POST /quizzes/generate` — generates an adaptive quiz.
  Future<GenerateQuizResponse> generateQuiz(GenerateQuizRequest request) async {
    final headers = await _getJsonHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/quizzes/generate'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    _assertSuccess(response, 'generateQuiz');
    return GenerateQuizResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// `POST /quizzes/submit` — submits answers and updates BKT mastery.
  Future<QuizSubmissionResponse> submitQuiz(QuizSubmissionRequest request) async {
    final headers = await _getJsonHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/quizzes/submit'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    _assertSuccess(response, 'submitQuiz');
    return QuizSubmissionResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Garden endpoints
  // -------------------------------------------------------------------------

  /// `GET /garden` — returns all subjects for the student with mastery snapshots.
  Future<List<GardenPlantModel>> getGarden() async {
    final headers = await _getJsonHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/garden'),
      headers: headers,
    );
    _assertSuccess(response, 'getGarden');
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => GardenPlantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /garden/{subjectId}/skills` — flat skill list with mastery for the detail screen.
  Future<List<SkillDetailModel>> getSubjectSkills(int subjectId) async {
    final headers = await _getJsonHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/garden/$subjectId/skills'),
      headers: headers,
    );
    _assertSuccess(response, 'getSubjectSkills');
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => SkillDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Document endpoints
  // -------------------------------------------------------------------------

  /// `POST /documents/upload` — uploads a PDF and starts async ingestion.
  ///
  /// The request is sent as `multipart/form-data` because the backend reads
  /// the file via FastAPI's [UploadFile].
  ///
  /// Parameters:
  /// - [pdfFile]: The [File] on the device's filesystem to upload.
  /// - [subjectId]: Which subject the document belongs to (default: `1`).
  ///
  /// Returns a [DocumentUploadResponse] immediately; the actual embedding and
  /// chunking happen asynchronously on the server.
  Future<DocumentUploadResponse> uploadDocument({
    required File pdfFile,
    required String subjectName,
    required String studentUid,
  }) async {
    final token = await _requireToken();

    final uri = Uri.parse('$baseUrl/api/v1/documents/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['subject_name'] = subjectName
      ..fields['student_uid'] = studentUid;

    request.files.add(await http.MultipartFile.fromPath(
        'file', // must match FastAPI's File(...) parameter name
        pdfFile.path,
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
          'uploadDocument failed [${response.statusCode}]: ${response.body}');
    }

    return DocumentUploadResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Gamification endpoints
  // -------------------------------------------------------------------------

  /// `GET /gamification/student/{uid}/profile` — fetch XP, coins, level.
  Future<Map<String, dynamic>> getGamificationProfile(String studentUid) async {
    final headers = await _getJsonHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/gamification/student/$studentUid/profile'),
      headers: headers,
    );
    _assertSuccess(response, 'getGamificationProfile');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `POST /gamification/student/{uid}/daily-login` — award daily bonus.
  Future<Map<String, dynamic>> checkDailyLogin(String studentUid) async {
    final headers = await _getJsonHeaders();
    final clientLocalDate = DateTime.now().toIso8601String().split('T')[0];
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/gamification/student/$studentUid/daily-login'),
      headers: headers,
      body: jsonEncode({'client_local_date': clientLocalDate}),
    );
    _assertSuccess(response, 'checkDailyLogin');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `POST /gamification/student/{uid}/spend-coins` — deduct coins.
  Future<int> spendCoins(String studentUid, int amount, String reason) async {
    final headers = await _getJsonHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/gamification/student/$studentUid/spend-coins'),
      headers: headers,
      body: jsonEncode({'amount': amount, 'reason': reason}),
    );
    _assertSuccess(response, 'spendCoins');
    final data = jsonDecode(response.body);
    return data['coins_total'] as int;
  }

  /// `GET /gamification/levels` — fetch static level definitions.
  Future<List<Map<String, dynamic>>> getLevels() async {
    final headers = await _getJsonHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/gamification/levels'),
      headers: headers,
    );
    _assertSuccess(response, 'getLevels');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['levels'] as List).cast<Map<String, dynamic>>();
  }

  // -------------------------------------------------------------------------
  // Analytics endpoints
  // -------------------------------------------------------------------------

  /// `POST /analytics/subjects/ensure` — create Subject rows for assigned subjects
  Future<void> ensureSubjects(List<String> subjectNames, String studentUid) async {
    final headers = await _getJsonHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/analytics/subjects/ensure'),
      headers: headers,
      body: jsonEncode({'student_uid': studentUid, 'subject_names': subjectNames}),
    );
    _assertSuccess(response, 'ensureSubjects');
  }

  /// `DELETE /analytics/subjects/{subject_name}` — securely wipe a custom subject
  Future<void> deleteSubject(String subjectName, String studentUid) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectName')
        .replace(queryParameters: {'student_uid': studentUid});
    final response = await http.delete(uri, headers: headers);
    _assertSuccess(response, 'deleteSubject');
  }
}
