// lib/src/services/notification_localizations.dart

import 'dart:ui' show Locale;

import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../bloc/locale/locale_cubit.dart' show kLocalePrefsKey;

/// Resolves the [AppLocalizations] matching the user's saved language
/// preference, for use by services and background isolates that have no
/// [BuildContext] — local notification text, WorkManager tasks.
class NotificationLocalizations {
  NotificationLocalizations._();

  /// Reads the locale code persisted by `LocaleCubit` and returns the
  /// matching [AppLocalizations] instance, falling back to English if no
  /// language has been chosen yet.
  static Future<AppLocalizations> current() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocalePrefsKey) ?? 'en';
    return lookupAppLocalizations(Locale(code));
  }
}
