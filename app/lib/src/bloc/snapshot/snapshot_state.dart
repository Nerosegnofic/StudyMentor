import 'package:equatable/equatable.dart';
import '../../domain/models/report_models.dart';

abstract class SnapshotState extends Equatable {
  const SnapshotState();

  @override
  List<Object?> get props => [];
}

class SnapshotInitial extends SnapshotState {}

class SnapshotLoading extends SnapshotState {}

class SnapshotLoaded extends SnapshotState {
  final DailyStudentSnapshotModel snapshot;

  const SnapshotLoaded(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

class SnapshotError extends SnapshotState {
  final String message;

  const SnapshotError(this.message);

  @override
  List<Object?> get props => [message];
}
