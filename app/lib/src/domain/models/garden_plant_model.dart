class GardenPlantModel {
  final int subjectId;
  final String subjectName;
  final double masteryPercent; // 0.0 – 100.0

  const GardenPlantModel({
    required this.subjectId,
    required this.subjectName,
    required this.masteryPercent,
  });

  factory GardenPlantModel.fromJson(Map<String, dynamic> json) {
    return GardenPlantModel(
      subjectId: json['subject_id'] as int,
      subjectName: json['subject_name'] as String,
      masteryPercent: (json['mastery_percent'] as num).toDouble(),
    );
  }
}
