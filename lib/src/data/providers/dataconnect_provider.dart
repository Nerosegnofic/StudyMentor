import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DataConnectProvider {
  final String endpoint;

  DataConnectProvider({required this.endpoint});

  Future<Map<String, dynamic>> _sendQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': query,
        'variables': variables ?? {},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('DataConnect error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['errors'] != null) {
      throw Exception(data['errors'][0]['message']);
    }

    return data['data'];
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String role,
  }) async {
    const mutation = r'''
      mutation CreateUser($uid: String!, $email: String!, $fullName: String!, $role: String!) {
        insertUser(uid: $uid, email: $email, fullName: $fullName, role: $role) {
          uid
        }
      }
    ''';

    await _sendQuery(mutation, variables: {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
    });
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    const query = r'''
      query GetUser($uid: String!) {
        user(uid: $uid) {
          uid
          email
          fullName
          role
          createdAt
        }
      }
    ''';

    final result = await _sendQuery(query, variables: {'uid': uid});
    return result['user'];
  }
}
