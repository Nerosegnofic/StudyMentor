// lib/src/domain/models/student_model.dart

class StudentModel {
  final String uid;
  final String fullName;
  final String email;
  final int? gradeLevel;
  final int? totalXp;
  final int? totalCoins;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  StudentModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.gradeLevel,
    this.totalXp,
    this.totalCoins,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastActiveAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    uid: json['uid'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    gradeLevel: json['grade_level'] as int?,
    totalXp: json['total_xp'] as int?,
    totalCoins: json['total_coins'] as int?,
    isEmailVerified: json['is_email_verified'] as bool? ?? false,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    lastActiveAt: json['last_active_at'] == null
        ? null
        : DateTime.parse(json['last_active_at'] as String),
  );

  StudentModel copyWith({
    bool? isEmailVerified,
    String? fullName,
    String? email,
  }) => StudentModel(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        gradeLevel: gradeLevel,
        totalXp: totalXp,
        totalCoins: totalCoins,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt,
      );
}
