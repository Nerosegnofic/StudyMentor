// test/bloc/quiz_bloc_test.dart
//
// Unit tests for QuizBloc.
// AiEngineRepository is injected so no Firebase or HTTP is needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/quiz/quiz_bloc.dart';
import 'package:studymentor/src/bloc/quiz/quiz_event.dart';
import 'package:studymentor/src/bloc/quiz/quiz_state.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/domain/models/gamification_enums.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GenerateQuizResponse _fakeResponse({int questionCount = 2}) {
  final questions = List.generate(
    questionCount,
    (i) => QuestionModel(
      questionId: 'q$i',
      topic: 'Topic $i',
      questionText: 'Question $i?',
      options: ['A', 'B', 'C', 'D'],
      correctAnswer: 'A',
      explanation: 'Because A.',
      difficulty: 2,
      hints: ['Hint $i'],
    ),
  );
  return GenerateQuizResponse(
    quizSessionId: 'session-123',
    selectedSubjectId: 1,
    selectedSubjectName: 'Math',
    quizTitle: 'Test Quiz',
    questions: questions,
  );
}

QuizSubmissionResponse _fakeSubmissionResponse() =>
    const QuizSubmissionResponse(
      score: 80.0,
      totalQuestions: 2,
      feedback: 'Great job!',
      rewards: {'xp_earned': 30},
    );

StudentAnswer _fakeAnswer(String questionId) => StudentAnswer(
      questionId: questionId,
      selectedOption: 'A',
      timeTakenMs: 3000,
      hintsUsed: 0,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAiEngineRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(
      const GenerateQuizRequest(totalQuestions: 5),
    );
    registerFallbackValue(
      QuizSubmissionRequest(
        quizSessionId: 'fallback',
        answers: const [],
        clientLocalDate: '2024-01-01',
      ),
    );
  });

  setUp(() {
    mockRepo = MockAiEngineRepository();
    // prewarmNextQuiz is fire-and-forget; stub it as no-op by default.
    when(() => mockRepo.prewarmNextQuiz(any())).thenAnswer((_) async {});
  });

  group('QuizBloc', () {
    // ── GenerateQuizEvent ────────────────────────────────────────────────────

    group('GenerateQuizEvent', () {
      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] on successful generation',
        build: () => QuizBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.generateQuiz(any()))
              .thenAnswer((_) async => _fakeResponse());
        },
        act: (bloc) => bloc.add(
          GenerateQuizEvent(
            subjectId: 1,
            totalQuestions: 2,
            studentGrade: 5,
            quizContext: QuizContext.voluntary,
          ),
        ),
        expect: () => [
          isA<QuizLoading>(),
          isA<QuizLoaded>().having(
            (s) => s.quizResponse.quizSessionId,
            'quizSessionId',
            'session-123',
          ),
        ],
        verify: (_) {
          verify(() => mockRepo.generateQuiz(any())).called(1);
        },
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] with correct question count',
        build: () => QuizBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.generateQuiz(any()))
              .thenAnswer((_) async => _fakeResponse(questionCount: 3));
        },
        act: (bloc) => bloc.add(GenerateQuizEvent(totalQuestions: 3)),
        expect: () => [
          isA<QuizLoading>(),
          isA<QuizLoaded>().having(
            (s) => s.quizResponse.questions.length,
            'questions.length',
            3,
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] when repository throws',
        build: () => QuizBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.generateQuiz(any()))
              .thenThrow(Exception('Server error'));
        },
        act: (bloc) => bloc.add(GenerateQuizEvent(totalQuestions: 5)),
        expect: () => [
          isA<QuizLoading>(),
          isA<QuizError>().having(
            (s) => s.message,
            'message',
            contains('Server error'),
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] with subject-still-preparing message',
        build: () => QuizBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.generateQuiz(any()))
              .thenThrow(const SubjectStillProcessingException());
        },
        act: (bloc) => bloc.add(GenerateQuizEvent(totalQuestions: 5)),
        expect: () => [
          isA<QuizLoading>(),
          isA<QuizError>().having(
            (s) => s.message,
            'message',
            kQuizSubjectStillPreparingError,
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'passes FORCED quiz context to the repository',
        build: () => QuizBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.generateQuiz(any()))
              .thenAnswer((_) async => _fakeResponse());
        },
        act: (bloc) => bloc.add(
          GenerateQuizEvent(
            totalQuestions: 5,
            quizContext: QuizContext.forced,
          ),
        ),
        verify: (_) {
          final captured = verify(
            () => mockRepo.generateQuiz(captureAny()),
          ).captured.single as GenerateQuizRequest;
          expect(captured.quizContext, 'FORCED');
        },
      );
    });

    // ── AnswerQuestionEvent ──────────────────────────────────────────────────

    group('AnswerQuestionEvent', () {
      blocTest<QuizBloc, QuizState>(
        'records an answer and emits updated QuizLoaded',
        build: () => QuizBloc(repository: mockRepo),
        seed: () => QuizLoaded(quizResponse: _fakeResponse()),
        act: (bloc) => bloc.add(AnswerQuestionEvent(_fakeAnswer('q0'))),
        expect: () => [
          isA<QuizLoaded>().having(
            (s) => s.currentAnswers.containsKey('q0'),
            'has answer for q0',
            true,
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'overwrites a previous answer for the same question',
        build: () => QuizBloc(repository: mockRepo),
        seed: () => QuizLoaded(
          quizResponse: _fakeResponse(),
          currentAnswers: {'q0': _fakeAnswer('q0')},
        ),
        act: (bloc) => bloc.add(
          AnswerQuestionEvent(
            StudentAnswer(
              questionId: 'q0',
              selectedOption: 'B',
              timeTakenMs: 5000,
              hintsUsed: 1,
            ),
          ),
        ),
        expect: () => [
          isA<QuizLoaded>().having(
            (s) => s.currentAnswers['q0']!.selectedOption,
            'selectedOption',
            'B',
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'does nothing when state is not QuizLoaded',
        build: () => QuizBloc(repository: mockRepo),
        // starts at QuizInitial
        act: (bloc) => bloc.add(AnswerQuestionEvent(_fakeAnswer('q0'))),
        expect: () => <QuizState>[],
      );
    });

    // ── SubmitQuizEvent ──────────────────────────────────────────────────────

    group('SubmitQuizEvent', () {
      blocTest<QuizBloc, QuizState>(
        'emits [QuizSubmitting, QuizResultsLoaded] on successful submission',
        build: () => QuizBloc(repository: mockRepo),
        seed: () => QuizLoaded(
          quizResponse: _fakeResponse(),
          currentAnswers: {'q0': _fakeAnswer('q0'), 'q1': _fakeAnswer('q1')},
        ),
        setUp: () {
          when(() => mockRepo.submitQuiz(any()))
              .thenAnswer((_) async => _fakeSubmissionResponse());
        },
        act: (bloc) => bloc.add(SubmitQuizEvent('session-123')),
        expect: () => [
          isA<QuizSubmitting>(),
          isA<QuizResultsLoaded>().having(
            (s) => s.result.score,
            'score',
            80.0,
          ),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizSubmitting, QuizError] when submission throws',
        build: () => QuizBloc(repository: mockRepo),
        seed: () =>
            QuizLoaded(quizResponse: _fakeResponse()),
        setUp: () {
          when(() => mockRepo.submitQuiz(any()))
              .thenThrow(Exception('Submit failed'));
        },
        act: (bloc) => bloc.add(SubmitQuizEvent('session-123')),
        expect: () => [
          isA<QuizSubmitting>(),
          isA<QuizError>(),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'does nothing when state is not QuizLoaded',
        build: () => QuizBloc(repository: mockRepo),
        act: (bloc) => bloc.add(SubmitQuizEvent('session-123')),
        expect: () => <QuizState>[],
      );
    });

    // ── ResetQuizEvent ───────────────────────────────────────────────────────

    group('ResetQuizEvent', () {
      blocTest<QuizBloc, QuizState>(
        'resets state to QuizInitial',
        build: () => QuizBloc(repository: mockRepo),
        seed: () => QuizLoaded(quizResponse: _fakeResponse()),
        act: (bloc) => bloc.add(ResetQuizEvent()),
        expect: () => [isA<QuizInitial>()],
      );
    });
  });
}
