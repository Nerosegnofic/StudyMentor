class SkillDetailModel {
  final String name;
  final double masteryPercent; // 0.0 – 100.0 (converted from backend 0-1)
  final int attempts;

  const SkillDetailModel({
    required this.name,
    required this.masteryPercent,
    required this.attempts,
  });

  bool get isStrong => attempts > 0 && masteryPercent >= 75;
  bool get isWeak => attempts > 0 && masteryPercent < 50;
  bool get isUntouched => attempts == 0;

  factory SkillDetailModel.fromJson(Map<String, dynamic> json) {
    return SkillDetailModel(
      name: json['name'] as String,
      masteryPercent: (json['mastery_percent'] as num).toDouble(),
      attempts: json['attempts'] as int? ?? 0,
    );
  }
}
