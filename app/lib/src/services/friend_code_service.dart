import 'dart:math';
import '../data/providers/dataconnect_provider.dart';

/// Generates a unique student friend code and persists it in DataConnect.
/// Format: first 4 alpha chars of first name (uppercased) + dash + 4 digits.
/// Example: ALEX-1248
class FriendCodeService {
  final DataConnectProvider _dataConnect;

  FriendCodeService(this._dataConnect);

  /// Returns the student's existing friend code if already stored, otherwise
  /// generates a new one, saves it, and returns it.
  Future<String> getOrCreate(String studentUid, String fullName) async {
    final profile = await _dataConnect.getStudentProfile(studentUid);
    final existing = profile['friend_code'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final code = _generate(fullName);
    await _dataConnect.updateStudentFriendCode(code);
    return code;
  }

  static String _generate(String fullName) {
    final firstName = fullName.trim().split(RegExp(r'\s+')).first;
    final letters =
        firstName.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = letters.length >= 4
        ? letters.substring(0, 4)
        : letters.padRight(4, 'X');
    final number = 1000 + Random().nextInt(9000);
    return '$prefix-$number';
  }
}
