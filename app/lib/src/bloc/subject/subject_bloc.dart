// lib/src/bloc/subject/subject_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'subject_event.dart';
import 'subject_state.dart';

class SubjectBloc extends Bloc<SubjectEvent, SubjectState> {
  final AuthRepository authRepository;

  SubjectBloc({required this.authRepository}) : super(SubjectInitial()) {
    on<LoadSubjectsRequested>(_onLoadSubjects);
    on<LoadAvailableSubjectsRequested>(_onLoadAvailableSubjects);
    on<AddSubjectsRequested>(_onAddSubjects);
    on<SelectGlobalSubjectsRequested>(_onSelectGlobalSubjects);
    on<RemoveSubjectRequested>(_onRemoveSubject);
    on<RemoveGlobalSubjectRequested>(_onRemoveGlobalSubject);
    on<ToggleSubjectSelectionRequested>(_onToggleSubjectSelection);
  }

  Future<void> _onLoadSubjects(
    LoadSubjectsRequested event,
    Emitter<SubjectState> emit,
  ) async {
    emit(SubjectsLoading());
    try {
      final subjects = await authRepository.getSubjectsByStudent(event.studentUid);
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onLoadAvailableSubjects(
    LoadAvailableSubjectsRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      final subjects = await authRepository.getAvailableSubjects(event.studentUid);
      emit(AvailableSubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onAddSubjects(
    AddSubjectsRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await authRepository.addSubjectsForStudent(
        studentUid: event.studentUid,
        subjectKeys: event.selectedKeys,
      );
      emit(SubjectAdded());
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onSelectGlobalSubjects(
    SelectGlobalSubjectsRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      // Adding a global from the catalog = selecting it (creates the profile row /
      // is_selected=True), which makes it active for the child.
      for (final subjectId in event.subjectIds) {
        await authRepository.setSubjectSelection(
          studentUid: event.studentUid,
          subjectId: subjectId,
          isSelected: true,
        );
      }
      emit(SubjectAdded());
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onRemoveSubject(
    RemoveSubjectRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await authRepository.removeSubject(
        studentUid: event.studentUid,
        subjectKey: event.subjectKey,
      );
      emit(SubjectRemoved(event.subjectKey));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onRemoveGlobalSubject(
    RemoveGlobalSubjectRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await authRepository.removeStudentSubjectData(
        studentUid: event.studentUid,
        subjectId: event.subjectId,
      );
      emit(SubjectRemoved(event.subjectId.toString()));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }

  Future<void> _onToggleSubjectSelection(
    ToggleSubjectSelectionRequested event,
    Emitter<SubjectState> emit,
  ) async {
    try {
      await authRepository.setSubjectSelection(
        studentUid: event.studentUid,
        subjectId: event.subjectId,
        isSelected: event.isSelected,
      );
      // Re-fetch and emit SubjectsLoaded directly (no SubjectsLoading) so the toggle
      // reflects the persisted state without flashing a full-screen spinner.
      final subjects = await authRepository.getSubjectsByStudent(event.studentUid);
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectsError(e.toString()));
    }
  }
}
