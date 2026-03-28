import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';

/// Utility for resolving the current [MyTheme] based on system brightness
/// and user preference.
class ThemeUtils {
  /// Resolves the current [MyTheme] from the theme viewmodel and system brightness.
  ///
  /// Uses [ref.watch] so the widget rebuilds when the theme changes.
  static MyTheme resolveMyTheme(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeState = ref.watch(themeViewModelProvider);
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    return themes[currentThemeType]!;
  }
}
