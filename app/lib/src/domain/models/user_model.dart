class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String,
    role: json['role'] as String,
  );
}
