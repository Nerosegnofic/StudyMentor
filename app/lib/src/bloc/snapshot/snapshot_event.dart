import 'package:equatable/equatable.dart';

abstract class SnapshotEvent extends Equatable {
  const SnapshotEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailySnapshotRequested extends SnapshotEvent {
  final String studentUid;

  const LoadDailySnapshotRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
