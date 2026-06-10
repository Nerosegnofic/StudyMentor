import 'package:equatable/equatable.dart';

abstract class GardenEvent extends Equatable {
  const GardenEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) the full garden for [studentUid].
class LoadGardenRequested extends GardenEvent {
  final String studentUid;
  const LoadGardenRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}
