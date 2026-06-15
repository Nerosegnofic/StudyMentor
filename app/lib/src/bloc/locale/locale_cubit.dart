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
  LocaleCubit() : super(const Locale('en'));

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocalePrefsKey);
    if (code != null) {
      emit(Locale(code));
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocalePrefsKey, locale.languageCode);
  }
}
