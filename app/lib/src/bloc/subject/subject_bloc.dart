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
    on<RemoveSubjectRequested>(_onRemoveSubject);
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
      final subjects = await authRepository.getAvailableSubjects();
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
}
