class SubjectProgressModel {
  final String studentUid;
  final String subjectKey;
  final int totalXp;
  final int level;
  final DateTime? updatedAt;

  const SubjectProgressModel({
    required this.studentUid,
    required this.subjectKey,
    required this.totalXp,
    required this.level,
    this.updatedAt,
  });

  SubjectProgressModel copyWith({
    int? totalXp,
    int? level,
    DateTime? updatedAt,
  }) {
    return SubjectProgressModel(
      studentUid: studentUid,
      subjectKey: subjectKey,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static SubjectProgressModel empty(String studentUid, String subjectKey) {
    return SubjectProgressModel(
      studentUid: studentUid,
      subjectKey: subjectKey,
      totalXp: 0,
      level: 1,
    );
  }
}
