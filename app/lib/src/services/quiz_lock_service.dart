import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/ai_engine_repository.dart';
import '../domain/models/gamification_enums.dart';

// ---------------------------------------------------------------------------
// QuizSessionData — full snapshot of an interrupted quiz session.
// ---------------------------------------------------------------------------
// Persisted to SharedPreferences as JSON so it survives process kills, task
// removal from recents, and device reboots. The native side keeps a boolean
// flag (quiz_lock_active) in its own prefs so UsageTimerService and
// BootReceiver can act without loading the Dart runtime.

class QuizSessionData {
  final GenerateQuizResponse quizResponse;
  final Map<String, StudentAnswer> answers;
  final int currentIndex;
  final int elapsedMs;
  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final bool autoLength;
  final int? subjectId;
  final int? studentGrade;

  const QuizSessionData({
    required this.quizResponse,
    required this.answers,
    required this.currentIndex,
    required this.elapsedMs,
    required this.studentId,
    required this.contextType,
    required this.totalQuestions,
    required this.autoLength,
    this.subjectId,
    this.studentGrade,
  });

  Map<String, dynamic> toJson() => {
        'quizResponse': quizResponse.toJson(),
        'answers': {
          for (final e in answers.entries) e.key: e.value.toJson(),
        },
        'currentIndex': currentIndex,
        'elapsedMs': elapsedMs,
        'studentId': studentId,
        'contextType':
            contextType == QuizContext.forced ? 'FORCED' : 'VOLUNTARY',
        'totalQuestions': totalQuestions,
        'autoLength': autoLength,
        'subjectId': subjectId,
        'studentGrade': studentGrade,
      };

  factory QuizSessionData.fromJson(Map<String, dynamic> json) =>
      QuizSessionData(
        quizResponse: GenerateQuizResponse.fromJson(
            json['quizResponse'] as Map<String, dynamic>),
        answers: {
          for (final e
              in (json['answers'] as Map<String, dynamic>).entries)
            e.key: StudentAnswer.fromJson(e.value as Map<String, dynamic>),
        },
        currentIndex: json['currentIndex'] as int,
        elapsedMs: json['elapsedMs'] as int,
        studentId: json['studentId'] as String,
        contextType: json['contextType'] == 'FORCED'
            ? QuizContext.forced
            : QuizContext.voluntary,
        totalQuestions: json['totalQuestions'] as int,
        autoLength: json['autoLength'] as bool,
        subjectId: json['subjectId'] as int?,
        studentGrade: json['studentGrade'] as int?,
      );
}

// ---------------------------------------------------------------------------
// QuizLockService — manages the mandatory quiz lock lifecycle.
// ---------------------------------------------------------------------------
// Responsibilities:
//   • Persist the active quiz session to SharedPreferences.
//   • Tell the native UsageTimerService when quiz lock is active/inactive so
//     it can enforce foreground and handle task-removal / boot recovery.
//
// Usage pattern:
//   saveSession(...)  — called when quiz starts and after each answered Q
//   clearSession()    — called when quiz completes or is reset
//   loadSession()     — called on app start to check for a pending restore

class QuizLockService {
  QuizLockService._();
  static final QuizLockService instance = QuizLockService._();

  static const _timerChannel =
      MethodChannel('com.example.studymentor/timer_service');
  static const _sessionKey = 'quiz_lock_session_data';

  Future<void> saveSession(QuizSessionData session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
      await _timerChannel
          .invokeMethod('setQuizLockActive', {'active': true});
    } catch (e) {
      debugPrint('[QuizLockService] saveSession error: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await _timerChannel
          .invokeMethod('setQuizLockActive', {'active': false});
    } catch (e) {
      debugPrint('[QuizLockService] clearSession error: $e');
    }
  }

  Future<QuizSessionData?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw == null) return null;
      return QuizSessionData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[QuizLockService] loadSession error: $e');
      return null;
    }
  }
}
