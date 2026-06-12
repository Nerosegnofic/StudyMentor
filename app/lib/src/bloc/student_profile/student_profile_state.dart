import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';

abstract class StudentProfileState extends Equatable {
  const StudentProfileState();

  @override
  List<Object?> get props => [];
}

class StudentProfileInitial extends StudentProfileState {}

class StudentProfileLoading extends StudentProfileState {}

class StudentProfileUpdateSuccess extends StudentProfileState {
  final StudentModel updatedStudent;

  const StudentProfileUpdateSuccess(this.updatedStudent);

  @override
  List<Object?> get props => [updatedStudent];
}

class StudentProfileError extends StudentProfileState {
  final String message;

  const StudentProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
