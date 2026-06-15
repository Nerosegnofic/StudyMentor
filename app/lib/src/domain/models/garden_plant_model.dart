class GardenPlantModel {
  final int subjectId;
  final String subjectName;
  final double masteryPercent; // 0.0 – 100.0

  /// When this subject's garden plant was last updated (i.e. last quiz
  /// submission for this subject). Null if the student has never studied
  /// this subject.
  final DateTime? updatedAt;

  const GardenPlantModel({
    required this.subjectId,
    required this.subjectName,
    required this.masteryPercent,
    this.updatedAt,
  });

  factory GardenPlantModel.fromJson(Map<String, dynamic> json) {
    return GardenPlantModel(
      subjectId: json['subject_id'] as int,
      subjectName: json['subject_name'] as String,
      masteryPercent: (json['mastery_percent'] as num).toDouble(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
