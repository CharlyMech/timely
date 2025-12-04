import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/config/theme.dart';
import 'package:timely/config/providers.dart';

class ThemeState {
  final ThemeType themeType;
  final bool isLoading;

  const ThemeState({required this.themeType, this.isLoading = false});

  ThemeState copyWith({ThemeType? themeType, bool? isLoading}) {
    return ThemeState(
      themeType: themeType ?? this.themeType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThemeViewModel extends Notifier<ThemeState> {
  static const String _themeKey = 'theme_preference';

  late SharedPreferences _prefs;

  Future<void> initialize(Brightness systemBrightness) async {
    state = state.copyWith(isLoading: true);

    final savedTheme = _prefs.getString(_themeKey);

    if (savedTheme != null) {
      final themeType = ThemeType.values.firstWhere(
        (t) => t.toString() == savedTheme,
        orElse: () => ThemeType.system,
      );
      state = state.copyWith(themeType: themeType, isLoading: false);
    } else {
      final systemTheme = systemBrightness == Brightness.dark
          ? ThemeType.dark
          : ThemeType.light;
      await _saveTheme(systemTheme);
      state = state.copyWith(themeType: systemTheme, isLoading: false);
    }
  }

  Future<void> setTheme(ThemeType themeType) async {
    await _saveTheme(themeType);
    state = state.copyWith(themeType: themeType);
  }

  Future<void> _saveTheme(ThemeType themeType) async {
    await _prefs.setString(_themeKey, themeType.toString());
  }

  ThemeData getThemeData(Brightness systemBrightness) {
    switch (state.themeType) {
      case ThemeType.light:
        return themes[ThemeType.light]!.toThemeData();
      case ThemeType.dark:
        return themes[ThemeType.dark]!.toThemeData();
      case ThemeType.system:
        return systemBrightness == Brightness.dark
            ? themes[ThemeType.dark]!.toThemeData()
            : themes[ThemeType.light]!.toThemeData();
    }
  }

  @override
  ThemeState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return const ThemeState(themeType: ThemeType.system);
  }
}

final themeViewModelProvider = NotifierProvider<ThemeViewModel, ThemeState>(
  ThemeViewModel.new,
);
