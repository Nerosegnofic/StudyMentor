import 'package:equatable/equatable.dart';
import '../../domain/models/user_model.dart';

abstract class ParentProfileState extends Equatable {
  const ParentProfileState();

  @override
  List<Object?> get props => [];
}

class ParentProfileInitial extends ParentProfileState {}

class ParentProfileLoading extends ParentProfileState {}

class ParentProfileUpdateSuccess extends ParentProfileState {
  final UserModel updatedUser;

  const ParentProfileUpdateSuccess(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

class EmailVerificationPending extends ParentProfileState {
  final String pendingEmail;

  const EmailVerificationPending(this.pendingEmail);

  @override
  List<Object?> get props => [pendingEmail];
}

class ParentAccountDeleted extends ParentProfileState {}

class ParentProfileError extends ParentProfileState {
  final String message;

  const ParentProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
