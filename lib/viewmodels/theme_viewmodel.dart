import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/config/theme.dart';
import 'package:timely/config/providers.dart';

/// Estado del tema de la aplicación
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

/// ViewModel para gestionar el tema de la aplicación
/// Maneja la persistencia con SharedPreferences y detecta el tema del sistema
class ThemeViewModel extends Notifier<ThemeState> {
  static const String _themeKey = 'theme_preference';

  late SharedPreferences _prefs;

  /// Inicializa el tema desde SharedPreferences o usa el del sistema
  Future<void> initialize(Brightness systemBrightness) async {
    state = state.copyWith(isLoading: true);

    // Leer preferencia guardada
    final savedTheme = _prefs.getString(_themeKey);

    if (savedTheme != null) {
      // Si hay tema guardado, usarlo
      final themeType = ThemeType.values.firstWhere(
        (t) => t.toString() == savedTheme,
        orElse: () => ThemeType.system,
      );
      state = state.copyWith(themeType: themeType, isLoading: false);
    } else {
      // Si no hay tema guardado, usar el del sistema y guardarlo
      final systemTheme = systemBrightness == Brightness.dark
          ? ThemeType.dark
          : ThemeType.light;
      await _saveTheme(systemTheme);
      state = state.copyWith(themeType: systemTheme, isLoading: false);
    }
  }

  /// Cambia el tema y lo persiste
  Future<void> setTheme(ThemeType themeType) async {
    await _saveTheme(themeType);
    state = state.copyWith(themeType: themeType);
  }

  /// Guarda el tema en SharedPreferences
  Future<void> _saveTheme(ThemeType themeType) async {
    await _prefs.setString(_themeKey, themeType.toString());
  }

  /// Obtiene el ThemeData actual según el tipo de tema
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

/// Provider del ThemeViewModel
/// Auto-dispone cuando no se usa
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(ThemeViewModel.new);
