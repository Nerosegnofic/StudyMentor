import 'package:equatable/equatable.dart';
import '../../domain/models/subject_progress_model.dart';
import '../../domain/models/skill_progress_model.dart';

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

/// All subject progress loaded — ready to render the home garden section.
class GardenLoaded extends GardenState {
  /// Map of subjectKey → SubjectProgressModel
  final Map<String, SubjectProgressModel> subjectProgress;

  /// If non-null, a level-up just occurred for this subject.
  final String? levelUpSubjectKey;

  const GardenLoaded({
    required this.subjectProgress,
    this.levelUpSubjectKey,
  });

  GardenLoaded copyWith({
    Map<String, SubjectProgressModel>? subjectProgress,
    String? levelUpSubjectKey,
    bool clearLevelUp = false,
  }) {
    return GardenLoaded(
      subjectProgress: subjectProgress ?? this.subjectProgress,
      levelUpSubjectKey: clearLevelUp ? null : (levelUpSubjectKey ?? this.levelUpSubjectKey),
    );
  }

  @override
  List<Object?> get props => [subjectProgress, levelUpSubjectKey];
}

/// Skills loaded for a specific subject — used on the detail page.
class SubjectSkillsLoaded extends GardenState {
  final String subjectKey;
  final SubjectProgressModel progress;
  final List<SkillProgressModel> skills;

  const SubjectSkillsLoaded({
    required this.subjectKey,
    required this.progress,
    required this.skills,
  });

  List<SkillProgressModel> get strongSkills =>
      skills.where((s) => s.isStrong).toList();

  List<SkillProgressModel> get weakSkills =>
      skills.where((s) => s.isWeak).toList();

  List<SkillProgressModel> get untouchedSkills =>
      skills.where((s) => s.totalAttempts == 0).toList();

  @override
  List<Object?> get props => [subjectKey, progress.totalXp, progress.level, skills.length];
}
