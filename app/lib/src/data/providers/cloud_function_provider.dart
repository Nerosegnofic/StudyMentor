import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionProvider {
  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
    region: 'us-east1',
  );

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String role,
  }) async {
    final callable = functions.httpsCallable('createUserProfile');
    await callable.call(<String, dynamic>{
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'role': role,
    });
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final callable = functions.httpsCallable('getUserProfile');
    final resp = await callable.call(<String, dynamic>{'uid': uid});
    return Map<String, dynamic>.from(resp.data);
  }
}
