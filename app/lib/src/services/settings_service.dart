import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-device student app preferences via SharedPreferences.
class SettingsService {
  static const _keyTimerNotification = 'student_timer_notification_enabled';
  static const _keyCooldownNotification =
      'student_cooldown_notification_enabled';

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  /// Controls the silent, persistent usage-time countdown notification.
  bool get timerNotificationEnabled =>
      _prefs.getBool(_keyTimerNotification) ?? true;

  /// Controls the silent, persistent cooldown countdown notification.
  /// The non-silent threshold alerts (5 min / 1 min / 10 s) are NOT
  /// affected by this toggle — they always fire.
  bool get cooldownNotificationEnabled =>
      _prefs.getBool(_keyCooldownNotification) ?? true;

  Future<void> setTimerNotificationEnabled(bool value) =>
      _prefs.setBool(_keyTimerNotification, value);

  Future<void> setCooldownNotificationEnabled(bool value) =>
      _prefs.setBool(_keyCooldownNotification, value);
}
