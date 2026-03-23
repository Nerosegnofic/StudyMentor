import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/cloud_function_provider.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthProvider firebase;
  final CloudFunctionProvider cloud;

  AuthRepositoryImpl({required this.firebase, required this.cloud});

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cred = await firebase.signUp(email, password);
    final uid = cred.user!.uid;
    // Send email verification
    await firebase.sendEmailVerification();
    // Create user profile in Postgres via cloud function (role default = Parent)
    await cloud.createUserProfile(
      uid: uid,
      email: email,
      fullName: fullName,
      role: 'Parent',
    );
    // Return a minimal user model (createdAt comes from backend in real response)
    final profile = await cloud.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await firebase.signIn(email, password);
    final current = firebase.currentUser!;
    final uid = current.uid;
    final profile = await cloud.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<void> sendEmailVerification() => firebase.sendEmailVerification();

  @override
  Future<bool> isEmailVerified() async {
    await firebase.reloadUser();
    return firebase.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() => firebase.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      firebase.sendPasswordReset(email);

  @override
  Future<UserModel?> getUserProfile() async {
    final user = firebase.currentUser;
    if (user == null) return null;
    final profile = await cloud.getUserProfile(user.uid);
    return UserModel.fromJson(profile);
  }
}
