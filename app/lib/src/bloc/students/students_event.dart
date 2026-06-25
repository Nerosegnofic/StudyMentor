import 'package:equatable/equatable.dart';
import '../../domain/models/app_config_model.dart';

abstract class StudentsEvent extends Equatable {
  const StudentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentsRequested extends StudentsEvent {
  final String parentUid;

  const LoadStudentsRequested({required this.parentUid});

  @override
  List<Object?> get props => [parentUid];
}

class CreateStudentRequested extends StudentsEvent {
  final String fullName;
  final String email;
  final String password;
  final String parentUid;
  final int gradeLevel;
  final List<AppRuleModel> rules;
  final StudentConfigModel config;

  const CreateStudentRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.parentUid,
    required this.gradeLevel,
    required this.rules,
    required this.config,
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        parentUid,
        gradeLevel,
        rules,
        config,
      ];
}

class DeleteStudentRequested extends StudentsEvent {
  final String studentUid;
  final String studentEmail;
  final String studentPassword;
  final String parentUid;

  const DeleteStudentRequested({
    required this.studentUid,
    required this.studentEmail,
    required this.studentPassword,
    required this.parentUid,
  });

  @override
  List<Object?> get props => [studentUid, studentEmail, studentPassword, parentUid];
}
