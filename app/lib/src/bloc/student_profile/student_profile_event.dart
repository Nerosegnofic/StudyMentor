import 'package:equatable/equatable.dart';

abstract class StudentProfileEvent extends Equatable {
  const StudentProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateStudentProfileRequested extends StudentProfileEvent {
  final String studentUid;
  final String studentEmail;
  final String? newFullName;
  final String? newGradeLevel;
  final String? newEmail;
  final String? currentPassword;
  final String? newPassword;

  const UpdateStudentProfileRequested({
    required this.studentUid,
    required this.studentEmail,
    this.newFullName,
    this.newGradeLevel,
    this.newEmail,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [
        studentUid,
        studentEmail,
        newFullName,
        newGradeLevel,
        newEmail,
        currentPassword,
        newPassword,
      ];
}
