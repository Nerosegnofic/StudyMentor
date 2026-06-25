// lib/src/domain/models/student_model.dart

class StudentModel {
  final String uid;
  final String fullName;
  final String email;
  final int? gradeLevel;
  final bool isEmailVerified;
  final DateTime? createdAt;

  StudentModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.gradeLevel,
    this.isEmailVerified = false,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    uid: json['uid'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    gradeLevel: json['grade_level'] as int?,
    isEmailVerified: json['is_email_verified'] as bool? ?? false,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
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
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        createdAt: createdAt,
      );
}
