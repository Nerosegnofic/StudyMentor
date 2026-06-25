import 'package:equatable/equatable.dart';
import '../../domain/models/gamification_models.dart';

abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {}

class GamificationLoaded extends GamificationState {
  final StudentGamificationModel profile;

  const GamificationLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Transient state emitted after a quiz is rewarded.
/// The UI can listen for this to trigger toast/modal animations,
/// then the BLoC immediately follows up with [GamificationLoaded].
class GamificationRewardProcessed extends GamificationState {
  final StudentGamificationModel profile;
  final int xpEarned;
  final int coinsEarned;
  final int? leveledUpTo;
  final bool streakIncremented;
  final int? milestoneHit;

  const GamificationRewardProcessed({
    required this.profile,
    required this.xpEarned,
    required this.coinsEarned,
    this.leveledUpTo,
    this.streakIncremented = false,
    this.milestoneHit,
  });

  @override
  List<Object?> get props => [profile, xpEarned, coinsEarned, leveledUpTo, streakIncremented, milestoneHit];
}

