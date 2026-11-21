// lib/core/providers/theme_provider.dart
//
// Provider transverse (P3.4) : mode de thème (clair/sombre/système),
// persisté dans SharedPreferences. Pose le mécanisme uniquement — aucune
// palette sombre n'existe encore dans le design system (`YekiTheme` n'a
// qu'un `light()`, confirmé par recherche exhaustive) ; la conception
// d'un vrai thème sombre est un travail de design séparé, hors périmètre
// d'un ticket d'infrastructure Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'theme_mode';

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

class ThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _themeModeFromString(prefs.getString(_kThemeModeKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _themeModeToString(mode));
    state = AsyncValue.data(mode);
  }
}

final themeProvider = AsyncNotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
