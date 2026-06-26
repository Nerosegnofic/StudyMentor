import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-device student app preferences via SharedPreferences.
class SettingsService {
  final SharedPreferences _prefs;
  final String _studentUid;

  SettingsService._(this._prefs, this._studentUid);

  static Future<SettingsService> create(String studentUid) async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs, studentUid);
  }

  String get _keyTimerNotification =>
      'student_${_studentUid}_timer_notification_enabled';
  String get _keyCooldownNotification =>
      'student_${_studentUid}_cooldown_notification_enabled';

  bool get timerNotificationEnabled =>
      _prefs.getBool(_keyTimerNotification) ?? true;

  bool get cooldownNotificationEnabled =>
      _prefs.getBool(_keyCooldownNotification) ?? true;

  Future<void> setTimerNotificationEnabled(bool value) =>
      _prefs.setBool(_keyTimerNotification, value);

  Future<void> setCooldownNotificationEnabled(bool value) =>
      _prefs.setBool(_keyCooldownNotification, value);

}
