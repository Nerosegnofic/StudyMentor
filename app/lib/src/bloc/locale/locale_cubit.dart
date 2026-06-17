// lib/src/bloc/locale/locale_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key under which the user's chosen app language is
/// persisted. Also read by [NotificationLocalizations] so background
/// services can localize notification text to match.
const kLocalePrefsKey = 'app_locale_code';

/// Persists the user's chosen app language (English/Arabic) across sessions.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(Locale initialLocale) : super(initialLocale);

  /// Reads the saved locale from SharedPreferences synchronously before
  /// the widget tree is built. Call this in main() before runApp() and pass
  /// the result to [LocaleCubit] so there is no flash of the wrong language.
  static Future<Locale> readSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocalePrefsKey);
    return code != null ? Locale(code) : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocalePrefsKey, locale.languageCode);
  }
}
