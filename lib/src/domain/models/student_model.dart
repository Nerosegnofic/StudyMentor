class StudentModel {
  final String uid;
  final String fullName;
  final String email;
  final int? gradeLevel;
  final int? totalXp;
  final int? totalCoins;

  StudentModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.gradeLevel,
    this.totalXp,
    this.totalCoins,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    uid: json['uid'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    gradeLevel: json['grade_level'] as int?,
    totalXp: json['total_xp'] as int?,
    totalCoins: json['total_coins'] as int?,
  );
}
