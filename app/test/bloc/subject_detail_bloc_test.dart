// test/bloc/subject_detail_bloc_test.dart
//
// Unit tests for SubjectDetailBloc.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_bloc.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_event.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_state.dart';
import 'package:studymentor/src/domain/models/skill_progress_model.dart';
import 'package:studymentor/src/domain/models/subject_summary_model.dart';
import 'package:studymentor/src/domain/models/quiz_attempt_model.dart';

import 'auth_bloc_test.dart' show FakeAuthRepository;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubjectSummaryModel _fakeSummary(String key) => SubjectSummaryModel(
      subjectKey: key,
      subjectId: 1,
      colorHex: '#2196F3',
      skillsCount: 3,
      masteryPercent: 60,
      quizzesCompleted: 5,
      totalTimeSpent: const Duration(minutes: 30),
      accuracyPercent: 75.0,
    );

List<SkillProgressModel> _fakeSkills(String subjectKey) => [
      SkillProgressModel(
        studentUid: 'uid-student',
        subjectKey: subjectKey,
        skillKey: 'algebra',
        correctAnswers: 8,
        wrongAnswers: 2,
        totalAttempts: 10,
      ),
      SkillProgressModel(
        studentUid: 'uid-student',
        subjectKey: subjectKey,
        skillKey: 'geometry',
        correctAnswers: 4,
        wrongAnswers: 6,
        totalAttempts: 10,
      ),
    ];

List<QuizAttemptModel> _fakeQuizzes() => [
      QuizAttemptModel(
        id: 'quiz-1',
        studentUid: 'uid-student',
        subjectKey: 'math',
        skillTag: 'algebra',
        attemptedAt: DateTime(2024, 1, 15),
        correctAnswers: 8,
        totalQuestions: 10,
        duration: const Duration(minutes: 12),
        passed: true,
        correctAnswerNumbers: [1, 2, 3, 4, 5, 6, 7, 8],
      ),
    ];

// A FakeAuthRepository that overrides the subject-detail methods.
class _FakeSubjectDetailRepo extends FakeAuthRepository {
  final bool shouldThrowOnLoad;

  _FakeSubjectDetailRepo({this.shouldThrowOnLoad = false});

  @override
  Future<SubjectSummaryModel> getSubjectOverview(
    String studentUid,
    int subjectId,
    String subjectKey,
  ) async {
    if (shouldThrowOnLoad) throw Exception('Load failed');
    return _fakeSummary(subjectKey);
  }

  @override
  Future<List<SkillProgressModel>> getSkillsForSubject(
    String studentUid,
    int subjectId,
    String subjectKey,
  ) async {
    if (shouldThrowOnLoad) throw Exception('Load failed');
    return _fakeSkills(subjectKey);
  }

  @override
  Future<List<QuizAttemptModel>> getAllQuizzes(
    String studentUid,
    int subjectId,
    String subjectKey,
  ) async {
    if (shouldThrowOnLoad) throw Exception('Load failed');
    return _fakeQuizzes();
  }

}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SubjectDetailBloc', () {
    // ── LoadSubjectDetailRequested ───────────────────────────────────────────

    group('LoadSubjectDetailRequested', () {
      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'emits [SubjectDetailLoading, SubjectDetailLoaded] on success',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(),
        ),
        act: (bloc) => bloc.add(
          const LoadSubjectDetailRequested(
            studentUid: 'uid-student',
            subjectId: 1,
            subjectKey: 'math',
          ),
        ),
        expect: () => [
          isA<SubjectDetailLoading>(),
          isA<SubjectDetailLoaded>(),
        ],
      );

      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'loaded state contains correct student uid and subject key',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(),
        ),
        act: (bloc) => bloc.add(
          const LoadSubjectDetailRequested(
            studentUid: 'uid-student',
            subjectId: 1,
            subjectKey: 'math',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as SubjectDetailLoaded;
          expect(state.studentUid, 'uid-student');
          expect(state.summary.subjectKey, 'math');
        },
      );

      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'loaded state contains skills from the repository',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(),
        ),
        act: (bloc) => bloc.add(
          const LoadSubjectDetailRequested(
            studentUid: 'uid-student',
            subjectId: 1,
            subjectKey: 'math',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as SubjectDetailLoaded;
          expect(state.skills.length, 2);
          expect(state.skills.first.skillKey, 'algebra');
        },
      );

      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'loaded state contains quiz attempts',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(),
        ),
        act: (bloc) => bloc.add(
          const LoadSubjectDetailRequested(
            studentUid: 'uid-student',
            subjectId: 1,
            subjectKey: 'math',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as SubjectDetailLoaded;
          expect(state.recentQuizzes.length, 1);
          expect(state.recentQuizzes.first.id, 'quiz-1');
        },
      );

      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'emits [SubjectDetailLoading, SubjectDetailError] when repository throws',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(shouldThrowOnLoad: true),
        ),
        act: (bloc) => bloc.add(
          const LoadSubjectDetailRequested(
            studentUid: 'uid-student',
            subjectId: 1,
            subjectKey: 'math',
          ),
        ),
        expect: () => [
          isA<SubjectDetailLoading>(),
          isA<SubjectDetailError>().having(
            (s) => s.message,
            'message',
            contains('Failed to load subject details'),
          ),
        ],
      );
    });

    // ── FetchSessionQuestionsRequested ───────────────────────────────────────

    group('FetchSessionQuestionsRequested', () {
      blocTest<SubjectDetailBloc, SubjectDetailState>(
        'does nothing when state is not SubjectDetailLoaded',
        build: () => SubjectDetailBloc(
          authRepository: _FakeSubjectDetailRepo(),
        ),
        act: (bloc) => bloc.add(
          const FetchSessionQuestionsRequested(quizAttemptId: 'quiz-1'),
        ),
        expect: () => <SubjectDetailState>[],
      );
    });
  });
}
