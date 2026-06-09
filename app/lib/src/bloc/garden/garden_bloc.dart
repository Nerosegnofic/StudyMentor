import 'package:bloc/bloc.dart';
import '../../data/catalog/subject_catalog.dart';
import '../../data/providers/dataconnect_provider.dart';
import '../../domain/models/subject_progress_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../utils/subject_xp_engine.dart';
import 'garden_event.dart';
import 'garden_state.dart';

/// XP values that put each catalog subject at a distinct growth stage on first load.
/// Index matches [SubjectCatalog.all]: Math, Science, History, English, Arabic.
const List<int> _seedXpByIndex = [0, 100, 300, 700, 1500];

class GardenBloc extends Bloc<GardenEvent, GardenState> {
  final DataConnectProvider _provider;

  GardenBloc({DataConnectProvider? provider})
      : _provider = provider ?? DataConnectProvider(),
        super(const GardenInitial()) {
    on<LoadGardenRequested>(_onLoad);
    on<LoadSubjectSkillsRequested>(_onLoadSkills);
    on<QuizCompletedForSubject>(_onQuizCompleted);
  }

  // ── Load garden ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadGardenRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(const GardenLoading());
    try {
      var rows = await _provider.getAllSubjectProgress(event.studentUid);

      // ── Seed missing subjects ─────────────────────────────────────────────
      // Seed any catalog subject that has no progress row yet (covers both
      // first-time users and cases where new subjects are added to the catalog).
      final existing = rows.map((r) => r.subjectKey).toSet();
      final missing = SubjectCatalog.all
          .asMap()
          .entries
          .where((e) => !existing.contains(e.value.key))
          .toList();
      if (missing.isNotEmpty) {
        await Future.wait([
          for (final entry in missing)
            _provider.upsertSubjectProgress(
              studentUid: event.studentUid,
              subjectKey: entry.value.key,
              totalXp: entry.key < _seedXpByIndex.length ? _seedXpByIndex[entry.key] : 0,
              level: SubjectXpEngine.levelFromXp(
                entry.key < _seedXpByIndex.length ? _seedXpByIndex[entry.key] : 0,
              ),
            ),
        ]);
        rows = await _provider.getAllSubjectProgress(event.studentUid);
      }

      final map = <String, SubjectProgressModel>{
        for (final r in rows) r.subjectKey: r,
      };
      emit(GardenLoaded(subjectProgress: map));
    } catch (e) {
      emit(GardenError(e.toString()));
    }
  }

  // ── Load skills for one subject ─────────────────────────────────────────────

  Future<void> _onLoadSkills(
    LoadSubjectSkillsRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(const GardenLoading());
    try {
      final progressRows = await _provider.getAllSubjectProgress(event.studentUid);
      final skillRows = await _provider.getSkillsForSubject(
        studentUid: event.studentUid,
        subjectKey: event.subjectKey,
      );

      final progress = progressRows.firstWhere(
        (r) => r.subjectKey == event.subjectKey,
        orElse: () => SubjectProgressModel.empty(event.studentUid, event.subjectKey),
      );

      emit(SubjectSkillsLoaded(
        subjectKey: event.subjectKey,
        progress: progress,
        skills: skillRows,
      ));
    } catch (e) {
      emit(GardenError(e.toString()));
    }
  }

  // ── Quiz completed ──────────────────────────────────────────────────────────

  Future<void> _onQuizCompleted(
    QuizCompletedForSubject event,
    Emitter<GardenState> emit,
  ) async {
    final result = event.result;

    // 1. Calculate earned XP
    final earnedXp = SubjectXpEngine.calculateXp(result);

    // 2. Fetch current subject progress (or start fresh)
    SubjectProgressModel current;
    try {
      final rows = await _provider.getAllSubjectProgress(event.studentUid);
      current = rows.firstWhere(
        (r) => r.subjectKey == result.subjectKey,
        orElse: () => SubjectProgressModel.empty(event.studentUid, result.subjectKey),
      );
    } catch (_) {
      current = SubjectProgressModel.empty(event.studentUid, result.subjectKey);
    }

    // 3. Compute new XP + level
    final newTotalXp = current.totalXp + earnedXp;
    final oldLevel = current.level;
    final newLevel = SubjectXpEngine.levelFromXp(newTotalXp);
    final didLevelUp = newLevel > oldLevel;

    // 4. Fetch current skill progress
    List<SkillProgressModel> skillRows;
    try {
      skillRows = await _provider.getSkillsForSubject(
        studentUid: event.studentUid,
        subjectKey: result.subjectKey,
      );
    } catch (_) {
      skillRows = [];
    }

    final existingSkill = skillRows.firstWhere(
      (s) => s.skillKey == result.skillKey,
      orElse: () => SkillProgressModel.empty(
        studentUid: event.studentUid,
        subjectKey: result.subjectKey,
        skillKey: result.skillKey,
      ),
    );

    final updatedSkill = existingSkill.copyWith(
      correctAnswers: existingSkill.correctAnswers + result.correctAnswers,
      wrongAnswers: existingSkill.wrongAnswers + result.wrongAnswers,
      totalAttempts: existingSkill.totalAttempts + result.totalQuestions,
      lastPracticedAt: DateTime.now(),
    );

    // 5. Persist subject XP update (skill progress is placeholder only — not persisted)
    try {
      await _provider.upsertSubjectProgress(
        studentUid: event.studentUid,
        subjectKey: result.subjectKey,
        totalXp: newTotalXp,
        level: newLevel,
      );
    } catch (_) {
      // Persistence failed — UI still updates optimistically
    }

    // 6. Emit updated state
    final currentState = state;
    if (currentState is GardenLoaded) {
      final updatedMap = Map<String, SubjectProgressModel>.from(currentState.subjectProgress);
      updatedMap[result.subjectKey] = SubjectProgressModel(
        studentUid: event.studentUid,
        subjectKey: result.subjectKey,
        totalXp: newTotalXp,
        level: newLevel,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(
        subjectProgress: updatedMap,
        levelUpSubjectKey: didLevelUp ? result.subjectKey : null,
      ));
    } else if (currentState is SubjectSkillsLoaded &&
        currentState.subjectKey == result.subjectKey) {
      final updatedSkillList = [
        ...currentState.skills.where((s) => s.skillKey != result.skillKey),
        updatedSkill,
      ];
      emit(SubjectSkillsLoaded(
        subjectKey: result.subjectKey,
        progress: SubjectProgressModel(
          studentUid: event.studentUid,
          subjectKey: result.subjectKey,
          totalXp: newTotalXp,
          level: newLevel,
          updatedAt: DateTime.now(),
        ),
        skills: updatedSkillList,
      ));
    }
  }
}
