import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-device student app preferences via SharedPreferences.
class SettingsService {
  static const _keyTimerNotification = 'student_timer_notification_enabled';
  static const _keyCooldownNotification =
      'student_cooldown_notification_enabled';
  static const _keyNotifications = 'student_notifications_enabled';
  static const _keySoundEffects = 'student_sound_effects_enabled';
  static const _keyBackgroundMusic = 'student_background_music_enabled';

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  bool get timerNotificationEnabled =>
      _prefs.getBool(_keyTimerNotification) ?? true;

  bool get cooldownNotificationEnabled =>
      _prefs.getBool(_keyCooldownNotification) ?? true;

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotifications) ?? true;

  bool get soundEffectsEnabled =>
      _prefs.getBool(_keySoundEffects) ?? true;

  bool get backgroundMusicEnabled =>
      _prefs.getBool(_keyBackgroundMusic) ?? false;

  Future<void> setTimerNotificationEnabled(bool value) =>
      _prefs.setBool(_keyTimerNotification, value);

  Future<void> setCooldownNotificationEnabled(bool value) =>
      _prefs.setBool(_keyCooldownNotification, value);

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotifications, value);

  Future<void> setSoundEffectsEnabled(bool value) =>
      _prefs.setBool(_keySoundEffects, value);

  Future<void> setBackgroundMusicEnabled(bool value) =>
      _prefs.setBool(_keyBackgroundMusic, value);
}
