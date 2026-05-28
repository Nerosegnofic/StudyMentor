import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';

abstract class StudentsState extends Equatable {
  const StudentsState();

  @override
  List<Object?> get props => [];
}

class StudentsInitial extends StudentsState {}

class StudentsLoading extends StudentsState {}

class StudentsLoaded extends StudentsState {
  final List<StudentModel> students;

  const StudentsLoaded(this.students);

  @override
  List<Object?> get props => [students];
}

class StudentsError extends StudentsState {
  final String message;

  const StudentsError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentCreateLoading extends StudentsState {}

class StudentCreated extends StudentsState {}

class StudentCreateError extends StudentsState {
  final String message;

  const StudentCreateError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentDeleteLoading extends StudentsState {}

class StudentDeleted extends StudentsState {
  final String studentUid;

  const StudentDeleted(this.studentUid);

  @override
  List<Object?> get props => [studentUid];
}

class StudentDeleteError extends StudentsState {
  final String message;

  const StudentDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}
