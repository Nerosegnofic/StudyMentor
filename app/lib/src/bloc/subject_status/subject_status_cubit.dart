import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/catalog/document_models.dart';
import '../../data/repositories/ai_engine_repository.dart';

/// Polls `GET /documents/subjects/status` and exposes the latest per-subject
/// ingestion readiness to the UI: it drives the parent "Preparing…" banner, the
/// upload-screen stage view, and the student Practice gate.
///
/// This is a **pure status source** — it does NOT trigger any quiz pre-warm. The
/// first-quiz warm now runs server-side at the end of ingestion (the only place
/// guaranteed to run when a subject becomes ready, since the parent uploads on the
/// student's behalf and may close the app).
///
/// Polling is caller-driven: call [start] when a relevant screen mounts and [close]
/// (or [stop]) on dispose. It polls on [pollInterval] for as long as it's running —
/// it does NOT auto-stop on the first idle tick (that was a bug: it killed the timer
/// before any upload began, so the processing→ready transition was never observed).
///
/// [studentUid]: a PARENT passes the child's uid so the poll reports that child's
/// subjects; a student instance omits it and the server uses the JWT uid.
class SubjectStatusCubit extends Cubit<SubjectStatusState> {
  SubjectStatusCubit({
    this.studentUid,
    AiEngineRepository? repository,
    this.pollInterval = const Duration(seconds: 12),
  })  : _repo = repository ?? AiEngineRepository.instance,
        super(const SubjectStatusState.initial());

  final String? studentUid;
  final AiEngineRepository _repo;
  final Duration pollInterval;

  Timer? _timer;

  /// Begin polling: fetch once immediately, then tick on [pollInterval]. Idempotent
  /// (a second call won't create a second timer).
  void start() {
    refresh();
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  /// Stop polling (call from the screen's dispose). Keeps the last emitted state.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One status fetch. Public so screens can also trigger a manual refresh
  /// (e.g. pull-to-refresh) without owning the timer.
  Future<void> refresh() async {
    List<SubjectStatus> statuses;
    try {
      statuses = await _repo.getSubjectsStatus(studentUid: studentUid);
    } catch (_) {
      // Transient failure — keep the previous state and try again next tick.
      return;
    }
    if (isClosed) return;

    final newState = SubjectStatusState(
      bySubjectId: {for (final s in statuses) s.subjectId: s},
    );
    emit(newState);

    // Nothing is ingesting — no point continuing to poll.
    if (!newState.hasProcessing) stop();
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}

class SubjectStatusState extends Equatable {
  /// Latest status per subject id. Empty until the first successful poll.
  final Map<int, SubjectStatus> bySubjectId;

  const SubjectStatusState({required this.bySubjectId});

  const SubjectStatusState.initial() : bySubjectId = const {};

  SubjectStatus? statusFor(int subjectId) => bySubjectId[subjectId];

  /// All subjects currently still ingesting (drives the parent "Preparing…" banner).
  List<SubjectStatus> get processing =>
      bySubjectId.values.where((s) => s.isProcessing).toList();

  bool get hasProcessing => bySubjectId.values.any((s) => s.isProcessing);

  @override
  List<Object?> get props => [bySubjectId];
}