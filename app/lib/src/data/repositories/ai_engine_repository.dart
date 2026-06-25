import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../catalog/document_models.dart';
import '../../domain/models/garden_plant_model.dart';
import '../../domain/models/skill_detail_model.dart';
import '../../domain/models/report_models.dart';
import '../../domain/models/ai_summary_model.dart';
import '../../domain/models/student_model.dart';

// ---------------------------------------------------------------------------
// Quiz DTOs (mirrors ai_engine/app/models/schemas/quiz_schemas.py)
// ---------------------------------------------------------------------------

class GenerateQuizRequest {
  final int? subjectId;
  final int totalQuestions;

  /// When true (parent picked "Auto"), the backend sizes the quiz adaptively and
  /// [totalQuestions] is ignored — it's only a fallback for the fixed case.
  final bool autoLength;
  final int studentGrade;

  /// "VOLUNTARY" (student chose to practice) or "FORCED" (parent/system mandated).
  /// Sent so the backend can label the session and grant the FORCED reward bonus.
  final String quizContext;

  const GenerateQuizRequest({
    this.subjectId,
    required this.totalQuestions,
    this.autoLength = false,
    this.studentGrade = 5,
    this.quizContext = 'VOLUNTARY',
  });

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'total_questions': totalQuestions,
        'auto_length': autoLength,
        'student_grade': studentGrade,
        'quiz_context': quizContext,
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

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'topic': topic,
        'question_text': questionText,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty,
        'hints': hints,
      };
}

class GenerateQuizResponse {
  final String quizSessionId;
  final int selectedSubjectId;
  final String selectedSubjectName;
  final List<QuestionModel> questions;

  const GenerateQuizResponse({
    required this.quizSessionId,
    required this.selectedSubjectId,
    required this.selectedSubjectName,
    required this.questions,
  });

  factory GenerateQuizResponse.fromJson(Map<String, dynamic> json) {
    return GenerateQuizResponse(
      quizSessionId: json['quiz_session_id'] as String,
      selectedSubjectId: json['selected_subject_id'] as int,
      selectedSubjectName: json['selected_subject_name'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'quiz_session_id': quizSessionId,
        'selected_subject_id': selectedSubjectId,
        'selected_subject_name': selectedSubjectName,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
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

  factory StudentAnswer.fromJson(Map<String, dynamic> json) => StudentAnswer(
        questionId: json['question_id'] as String,
        selectedOption: json['selected_option'] as String,
        timeTakenMs: json['time_taken_ms'] as int,
        hintsUsed: json['hints_used'] as int,
      );

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
  /// Foreground-only solve time from the client stopwatch (ms).
  /// Pauses when the app is backgrounded; used server-side to compute accurate
  /// study time (end_time = start_time + totalElapsedMs).
  final int totalElapsedMs;

  const QuizSubmissionRequest({
    required this.quizSessionId,
    required this.answers,
    required this.clientLocalDate,
    required this.totalElapsedMs,
  });

  Map<String, dynamic> toJson() => {
        'quiz_session_id': quizSessionId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'client_local_date': clientLocalDate,
        'total_elapsed_ms': totalElapsedMs,
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

/// Thrown when an upload is rejected because a document for the same subject is
/// still ingesting (server returns 409). The bloc maps this to a friendly
/// "please wait" message.
class SubjectStillProcessingException implements Exception {
  const SubjectStillProcessingException();
  @override
  String toString() => 'SubjectStillProcessingException';
}

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

  static const String defaultBaseUrl = 'http://192.168.100.2:8000';

  /// Lazy singleton — created on first access, reused everywhere.
  static final AiEngineRepository instance = AiEngineRepository(
    baseUrl: defaultBaseUrl,
  );

  final String baseUrl;
  final FirebaseAuth _auth;
  final http.Client _client;

  AiEngineRepository({
    required this.baseUrl,
    FirebaseAuth? auth,
    http.Client? client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/quizzes/generate'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    // 409 = subject's curriculum is still ingesting (the server backstop). Surface it
    // typed so the bloc shows the friendly "still preparing" message.
    if (response.statusCode == 409) {
      throw const SubjectStillProcessingException();
    }
    _assertSuccess(response, 'generateQuiz');
    return GenerateQuizResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Fire-and-forget pre-generation of the *next* quiz.
  ///
  /// Calling `/generate` proactively (typically right after a submit) makes the
  /// AI engine create an unsubmitted session and persist its questions — that is
  /// the engine's quiz cache. The next real `generateQuiz` for the same
  /// `(student, subject)` then returns it instantly as `quiz_source="CACHED"`.
  ///
  /// `POST /quizzes/warm` — fire-and-forget pre-generation of a cached quiz for
  /// EVERY active subject.
  ///
  /// Tells the engine to top up the cache for all of the student's active subjects,
  /// so the next `generateQuiz` for ANY subject — voluntary or forced — returns
  /// instantly as `quiz_source="CACHED"`. The engine is idempotent: subjects that
  /// already have a cached quiz are skipped, so this is cheap once caches are full.
  ///
  /// Called right after a successful submit (refills the just-consumed subject) and
  /// on app foreground / dashboard load (fills subjects that went cold via ingestion
  /// while the app was closed). The response is discarded and any error is swallowed —
  /// warming is best-effort and must never surface to the user.
  Future<void> warmAllQuizzes() async {
    try {
      final headers = await _getJsonHeaders();
      await _client.post(
        Uri.parse('$baseUrl/api/v1/quizzes/warm'),
        headers: headers,
      );
    } catch (_) {
      // best-effort warming — ignore failures (network, auth refresh, etc.)
    }
  }

  /// `POST /quizzes/submit` — submits answers and updates BKT mastery.
  Future<QuizSubmissionResponse> submitQuiz(QuizSubmissionRequest request) async {
    final headers = await _getJsonHeaders();
    final response = await _client.post(
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
    final response = await _client.get(
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
    final response = await _client.get(
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
  /// Returns immediately once the server accepts the upload; the actual
  /// embedding and chunking happen asynchronously on the server.
  Future<void> uploadDocument({
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

    // 409 = a document for this subject is still ingesting (the server's concurrent-
    // upload guard). Surface it as a typed exception so the bloc can show a friendly
    // "still processing" message rather than a generic failure.
    if (response.statusCode == 409) {
      throw const SubjectStillProcessingException();
    }
    if (response.statusCode != 200) {
      throw Exception(
          'uploadDocument failed [${response.statusCode}]: ${response.body}');
    }
  }

  /// `GET /documents/subjects/status` — per-subject ingestion readiness for the
  /// current student. Polled (only while something is processing) to drive the
  /// "Preparing…" indicator, gate the Practice button, and detect the
  /// processing→ready edge that triggers the first-quiz pre-warm.
  /// [studentUid]: a PARENT passes the child's uid to see that child's subjects
  /// (the parent uploads on the child's behalf); a student omits it and the
  /// JWT uid is used server-side. Mirrors `getSubjectsAnalytics`.
  Future<List<SubjectStatus>> getSubjectsStatus({String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/documents/subjects/status').replace(
      queryParameters: studentUid != null ? {'student_uid': studentUid} : null,
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectsStatus');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (body['subjects'] as List? ?? const []);
    return list
        .map((e) => SubjectStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Gamification endpoints
  // -------------------------------------------------------------------------

  /// `GET /gamification/student/{uid}/profile` — fetch XP, coins, level.
  Future<Map<String, dynamic>> getGamificationProfile(String studentUid) async {
    final headers = await _getJsonHeaders();
    final response = await _client.get(
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
    final response = await _client.post(
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
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/gamification/student/$studentUid/spend-coins'),
      headers: headers,
      body: jsonEncode({'amount': amount, 'reason': reason}),
    );
    _assertSuccess(response, 'spendCoins');
    final data = jsonDecode(response.body);
    return data['coins_total'] as int;
  }

  // -------------------------------------------------------------------------
  // Analytics endpoints
  // -------------------------------------------------------------------------

  /// `POST /analytics/subjects/ensure` — create Subject rows for assigned subjects
  Future<void> ensureSubjects(List<String> subjectNames, String studentUid) async {
    final headers = await _getJsonHeaders();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/analytics/subjects/ensure'),
      headers: headers,
      body: jsonEncode({'student_uid': studentUid, 'subject_names': subjectNames}),
    );
    _assertSuccess(response, 'ensureSubjects');
  }

  /// `GET /analytics/subjects` — returns every subject the student is enrolled in with stats
  Future<List<Map<String, dynamic>>> getSubjectsAnalytics({String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects').replace(
      queryParameters: studentUid != null ? {'student_uid': studentUid} : null,
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectsAnalytics');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// `GET /analytics/subjects/{id}/mastery` — returns unit/lesson/skill mastery tree
  Future<Map<String, dynamic>> getSubjectMasteryTree(int subjectId, {String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectId/mastery').replace(
      queryParameters: studentUid != null ? {'student_uid': studentUid} : null,
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectMasteryTree');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `GET /analytics/subjects/{id}/history` — returns paginated quiz sessions
  Future<Map<String, dynamic>> getSubjectQuizHistory(int subjectId, {int page = 1, int pageSize = 10, String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (studentUid != null) {
      queryParams['student_uid'] = studentUid;
    }
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectId/history').replace(
      queryParameters: queryParams,
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectQuizHistory');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `GET /analytics/sessions/{sessionId}/questions` — per-question review data for a completed quiz.
  Future<Map<String, dynamic>> getSessionQuestions(String sessionId, {String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/sessions/$sessionId/questions').replace(
      queryParameters: studentUid != null ? {'student_uid': studentUid} : null,
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSessionQuestions');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `DELETE /analytics/students/{studentUid}` — wipe all AI-engine data for a student.
  /// Called during student account deletion; uses the parent's JWT for auth.
  Future<void> deleteStudentAllData(String studentUid) async {
    final headers = await _getJsonHeaders();
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/analytics/students/$studentUid'),
      headers: headers,
    );
    _assertSuccess(response, 'deleteStudentAllData');
  }

  /// `DELETE /analytics/subjects/{subject_name}` — securely wipe a custom subject
  Future<void> deleteSubject(String subjectName, String studentUid) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectName')
        .replace(queryParameters: {'student_uid': studentUid});
    final response = await _client.delete(uri, headers: headers);
    _assertSuccess(response, 'deleteSubject');
  }

  /// `PATCH /subjects/{id}/selection` — select/deselect a subject for a student
  /// (parent focus control). Deselected subjects are hidden from the student and
  /// excluded from quizzes; the subject and its data are preserved either way.
  Future<void> setSubjectSelection({
    required int subjectId,
    required String studentUid,
    required bool isSelected,
  }) async {
    final headers = await _getJsonHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/subjects/$subjectId/selection'),
      headers: headers,
      body: jsonEncode({'student_uid': studentUid, 'is_selected': isSelected}),
    );
    _assertSuccess(response, 'setSubjectSelection');
  }

  /// `GET /subjects/available` — global subjects the parent hasn't yet added for this
  /// student (the Add-Subjects catalog). Returns `[{subject_id, name, color_hex}]`.
  Future<List<Map<String, dynamic>>> getAvailableGlobalSubjects(String studentUid) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/subjects/available')
        .replace(queryParameters: {'student_uid': studentUid});
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getAvailableGlobalSubjects');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// `DELETE /subjects/{id}/student-data` — remove a GLOBAL subject from a child: wipes the
  /// child's progress in it and returns it to the catalog, without deleting the shared subject.
  Future<void> removeStudentSubjectData(int subjectId, String studentUid) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/subjects/$subjectId/student-data')
        .replace(queryParameters: {'student_uid': studentUid});
    final response = await _client.delete(uri, headers: headers);
    _assertSuccess(response, 'removeStudentSubjectData');
  }

  // -------------------------------------------------------------------------
  // Snapshot & reporting endpoints
  // -------------------------------------------------------------------------

  /// `GET /gamification/student/{uid}/daily-snapshot` — real today's stats.
  Future<DailyStudentSnapshotModel> getDailySnapshot(String studentUid) async {
    final headers = await _getJsonHeaders();
    final clientLocalDate = DateTime.now().toIso8601String().split('T')[0];
    final uri = Uri.parse(
      '$baseUrl/api/v1/gamification/student/$studentUid/daily-snapshot',
    ).replace(queryParameters: {'client_local_date': clientLocalDate});
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getDailySnapshot');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bySubjectRaw =
        (data['questions_by_subject'] as List<dynamic>?) ?? const [];
    return DailyStudentSnapshotModel(
      quizzesCompletedToday: (data['quizzes_today'] as int?) ?? 0,
      totalStudyTimeToday: Duration(minutes: (data['study_time_minutes'] as int?) ?? 0),
      averageAccuracyToday: (data['accuracy_today'] as int?) ?? 0,
      questionsBySubject: bySubjectRaw
          .map((e) =>
              SubjectQuestionCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// `GET /gamification/student/{uid}/weekly-report` — real 7-day stats.
  Future<WeeklyReportModel> getWeeklyReport(String studentUid) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse(
      '$baseUrl/api/v1/gamification/student/$studentUid/weekly-report',
    );
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getWeeklyReport');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final trendRaw = (data['accuracy_trend'] as List<dynamic>?) ?? [];
    final trend = trendRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return WeeklyAccuracyPoint(
        weekLabel: m['week_label'] as String,
        accuracy: (m['accuracy'] as num).toDouble(),
      );
    }).toList();

    final allocRaw = (data['subject_allocations'] as List<dynamic>?) ?? [];
    final allocations = allocRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return SubjectTimeAllocation(
        subjectKey: (m['subject_key'] as String?) ?? '',
        percentage: (m['percentage'] as num?)?.toDouble() ?? 0.0,
        colorHex: (m['color_hex'] as String?) ?? '#2196F3',
      );
    }).toList();

    final alertsRaw = (data['alerts'] as List<dynamic>?) ?? [];
    final alerts = alertsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return AlertModel(
        severity: (m['severity'] as String?) ?? 'info',
        message: (m['message'] as String?) ?? '',
      );
    }).toList();

    return WeeklyReportModel(
      overallAccuracyPercent: (data['overall_accuracy_percent'] as num?)?.toDouble() ?? 0.0,
      totalQuizzes: (data['total_quizzes'] as int?) ?? 0,
      totalStudyTime: Duration(minutes: (data['study_time_minutes'] as int?) ?? 0),
      currentStreakDays: (data['current_streak_days'] as int?) ?? 0,
      longestStreakDays: (data['longest_streak_days'] as int?) ?? 0,
      accuracyTrend: trend,
      subjectAllocations: allocations,
      aiInsightText: (data['ai_insight_text'] as String?) ?? '',
      voluntaryQuizzes: (data['voluntary_quizzes'] as int?) ?? 0,
      forcedQuizzes: (data['forced_quizzes'] as int?) ?? 0,
      guessingSessions: (data['guessing_sessions'] as int?) ?? 0,
      accuracyDelta: (data['accuracy_delta'] as num?)?.toDouble(),
      studyMinutesDelta: (data['study_minutes_delta'] as int?) ?? 0,
      quizzesDelta: (data['quizzes_delta'] as int?) ?? 0,
      alerts: alerts,
    );
  }

  /// `GET /gamification/student/{uid}/study-habits` — real streaks + study-time
  /// series (28-day heatmap + last 7 days) for the Habits tab.
  Future<StudyHabitsReport> getStudyHabitsReport(String studentUid) async {
    final headers = await _getJsonHeaders();
    final now = DateTime.now();
    final clientLocalDate = now.toIso8601String().split('T')[0];
    final uri = Uri.parse(
      '$baseUrl/api/v1/gamification/student/$studentUid/study-habits',
    ).replace(queryParameters: {
      'client_local_date': clientLocalDate,
      'tz_offset_minutes': now.timeZoneOffset.inMinutes.toString(),
    });
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getStudyHabitsReport');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final heatRaw = (data['consistency_heatmap'] as List<dynamic>?) ?? [];
    final heatmap = heatRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return HeatmapDay(
        studyMinutes: (m['study_minutes'] as int?) ?? 0,
      );
    }).toList();

    final dailyRaw = (data['daily_study'] as List<dynamic>?) ?? [];
    final daily = dailyRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return DailyStudyPoint(
        dayLabel: (m['day_label'] as String?) ?? '',
        studyMinutes: (m['study_minutes'] as int?) ?? 0,
      );
    }).toList();

    final todRaw = (data['time_of_day'] as List<dynamic>?) ?? [];
    final timeOfDay = todRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return TimeOfDayPoint(
        label: (m['label'] as String?) ?? '',
        minutes: (m['minutes'] as int?) ?? 0,
      );
    }).toList();

    return StudyHabitsReport(
      currentStreakDays: (data['current_streak_days'] as int?) ?? 0,
      longestStreakDays: (data['longest_streak_days'] as int?) ?? 0,
      consistencyHeatmap: heatmap,
      dailyStudy: daily,
      timeOfDay: timeOfDay,
    );
  }

  /// Subjects available for the Mastery tab's chip row, with cached mastery.
  /// Backed by `GET /analytics/subjects`.
  Future<List<SubjectChipModel>> getReportSubjects(String studentUid) async {
    final subjects = await getSubjectsAnalytics(studentUid: studentUid);
    return subjects
        .map((s) => SubjectChipModel(
              id: s['subject_id'] as int,
              name: (s['name'] as String?) ?? '',
            ))
        .toList();
  }

  /// Real subject mastery report built from `/analytics/subjects` (for the
  /// subject's average mastery) and `/analytics/subjects/{id}/mastery` (for the
  /// skill tree). Strong = mastery ≥ 75%; Needs-work = attempted but < 50%.
  Future<SubjectMasteryReport> getSubjectMasteryReport(
    String studentUid,
    int subjectId,
  ) async {
    final results = await Future.wait([
      getSubjectsAnalytics(studentUid: studentUid),
      getSubjectMasteryTree(subjectId, studentUid: studentUid),
      getSubjectErrorBreakdown(subjectId, studentUid: studentUid),
      getSubjectMasteryHistory(subjectId, studentUid: studentUid),
    ]);
    final subjects = results[0] as List<Map<String, dynamic>>;
    final tree = results[1] as Map<String, dynamic>;
    final breakdown = results[2] as Map<String, dynamic>;
    final historyData = results[3] as Map<String, dynamic>;

    final meta = subjects.firstWhere(
      (s) => s['subject_id'] == subjectId,
      orElse: () => <String, dynamic>{},
    );
    final totalMastery = ((meta['average_mastery'] as num?)?.toDouble() ?? 0.0) * 100.0;
    final subjectName =
        (tree['subject_name'] as String?) ?? (meta['name'] as String?) ?? '';

    final all = <MasterySkill>[];
    for (final unit in (tree['units'] as List? ?? const [])) {
      for (final lesson in ((unit as Map)['lessons'] as List? ?? const [])) {
        for (final skill in ((lesson as Map)['skills'] as List? ?? const [])) {
          final m = skill as Map<String, dynamic>;
          all.add(MasterySkill(
            name: (m['name'] as String?) ?? '',
            masteryPercent: ((m['mastery'] as num?)?.toDouble() ?? 0.0) * 100.0,
          ));
        }
      }
    }

    final strong = all.where((s) => s.masteryPercent >= 75).toList()
      ..sort((a, b) => b.masteryPercent.compareTo(a.masteryPercent));
    final weak = all
        .where((s) => s.masteryPercent < 50)
        .toList()
      ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));

    // Error breakdown (only meaningful once the student has wrong answers).
    final errRaw = (breakdown['error_breakdown'] as Map<String, dynamic>?) ?? {};
    final totalErrors = (errRaw['total_errors'] as int?) ?? 0;
    final errorAnalytics = totalErrors > 0
        ? ErrorAnalyticModel(
            carelessPercent: (errRaw['careless_percent'] as num?)?.toDouble() ?? 0.0,
            conceptGapPercent: (errRaw['concept_gap_percent'] as num?)?.toDouble() ?? 0.0,
            guessingPercent: (errRaw['guessing_percent'] as num?)?.toDouble() ?? 0.0,
          )
        : null;

    final diffRaw = (breakdown['difficulty_accuracy'] as List<dynamic>?) ?? [];
    final difficultyAccuracy = diffRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return DifficultyAccuracy(
        difficulty: (m['difficulty'] as int?) ?? 0,
        total: (m['total'] as int?) ?? 0,
        accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final histRaw = (historyData['history'] as List<dynamic>?) ?? [];
    final masteryHistory = histRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return MasteryHistoryPoint(
        mastery: (m['mastery'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return SubjectMasteryReport(
      subjectKey: subjectName,
      totalMasteryPercent: totalMastery,
      masteryLabel: _masteryLabel(totalMastery),
      strongSkills: strong.take(8).toList(),
      weakSkills: weak.take(8).toList(),
      errorAnalytics: errorAnalytics,
      difficultyAccuracy: difficultyAccuracy,
      masteryHistory: masteryHistory,
    );
  }

  /// `GET /analytics/subjects/{id}/mastery-history` — daily mastery snapshots.
  Future<Map<String, dynamic>> getSubjectMasteryHistory(int subjectId, {String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectId/mastery-history')
        .replace(queryParameters: studentUid != null ? {'student_uid': studentUid} : null);
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectMasteryHistory');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `GET /analytics/subjects/{id}/error-breakdown` — careless/concept/guessing
  /// split plus per-difficulty accuracy.
  Future<Map<String, dynamic>> getSubjectErrorBreakdown(int subjectId, {String? studentUid}) async {
    final headers = await _getJsonHeaders();
    final uri = Uri.parse('$baseUrl/api/v1/analytics/subjects/$subjectId/error-breakdown')
        .replace(queryParameters: studentUid != null ? {'student_uid': studentUid} : null);
    final response = await _client.get(uri, headers: headers);
    _assertSuccess(response, 'getSubjectErrorBreakdown');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String _masteryLabel(double percent) {
    if (percent >= 90) return 'Expert';
    if (percent >= 75) return 'Proficient';
    if (percent >= 50) return 'Developing';
    if (percent > 0) return 'Beginner';
    return 'Not Started';
  }

  /// `POST /analytics/parent/daily-summary` — per-child daily summary slides
  /// (household headline + one slide per child) for the parent home page.
  Future<AiSummaryModel> getAiSummary(List<StudentModel> children) async {
    final headers = await _getJsonHeaders();
    final clientLocalDate = DateTime.now().toIso8601String().split('T')[0];
    final uri = Uri.parse('$baseUrl/api/v1/analytics/parent/daily-summary');
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'children':
            children.map((s) => {'uid': s.uid, 'name': s.fullName}).toList(),
        'client_local_date': clientLocalDate,
      }),
    );
    _assertSuccess(response, 'getAiSummary');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final slidesRaw = (data['slides'] as List<dynamic>?) ?? [];
    final slides = slidesRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return AiSummarySlide(
        childUid: m['child_uid'] as String?,
        text: (m['text'] as String?) ?? '',
        severity: (m['severity'] as String?) ?? 'info',
      );
    }).toList();

    return AiSummaryModel(slides: slides);
  }
}
