import 'package:equatable/equatable.dart';

abstract class ParentProfileEvent extends Equatable {
  const ParentProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateParentProfileRequested extends ParentProfileEvent {
  final String parentUid;
  final String? newFullName;
  final String? newEmail;
  final String? currentPassword;
  final String? newPassword;

  const UpdateParentProfileRequested({
    required this.parentUid,
    this.newFullName,
    this.newEmail,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [parentUid, newFullName, newEmail, currentPassword, newPassword];
}

class DeleteParentAccountRequested extends ParentProfileEvent {
  final String parentUid;
  final String currentPassword;

  const DeleteParentAccountRequested({
    required this.parentUid,
    required this.currentPassword,
  });

  @override
  List<Object?> get props => [parentUid, currentPassword];
}
