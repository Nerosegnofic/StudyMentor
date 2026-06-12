import 'package:equatable/equatable.dart';
import '../../domain/models/garden_plant_model.dart';

abstract class GardenState extends Equatable {
  const GardenState();
  @override
  List<Object?> get props => [];
}

class GardenInitial extends GardenState {
  const GardenInitial();
}

class GardenLoading extends GardenState {
  const GardenLoading();
}

class GardenError extends GardenState {
  final String message;
  const GardenError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Garden loaded — [plants] is empty when no subjects have been assigned yet.
class GardenLoaded extends GardenState {
  final List<GardenPlantModel> plants;

  const GardenLoaded({required this.plants});

  @override
  List<Object?> get props => [plants];
}
