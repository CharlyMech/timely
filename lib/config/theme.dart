import 'package:flutter/material.dart';
import 'package:timely/constants/themes.dart';

extension MyThemeToThemeData on MyTheme {
  ThemeData toThemeData() {
    return ThemeData(
      primaryColor: _parseColor(primaryColor),
      scaffoldBackgroundColor: _parseColor(backgroundColor),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _parseColor(onBackgroundColor)),
        bodyMedium: TextStyle(color: _parseColor(onBackgroundColor)),
      ),
      colorScheme: ColorScheme(
        primary: _parseColor(primaryColor),
        secondary: _parseColor(inactiveColor),
        surface: _parseColor(surfaceColor),
        error: _parseColor(colorRed),
        onPrimary: _parseColor(onPrimaryColor),
        onSecondary: _parseColor(onInactiveColor),
        onSurface: _parseColor(onSurfaceColor),
        onError: _parseColor(onRedColor),
        brightness: this == themes[ThemeType.light]
            ? Brightness.light
            : Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 1,
        shadowColor: _parseColor(shadow),
        scrolledUnderElevation: 1,
        surfaceTintColor: _parseColor(backgroundColor),
        backgroundColor: _parseColor(surfaceColor),
        foregroundColor: _parseColor(onPrimaryColor),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _parseColor(primaryColor),
        iconSize: 40,
        foregroundColor: _parseColor(onPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(_parseColor(primaryColor)),
          foregroundColor: WidgetStateProperty.all(_parseColor(onPrimaryColor)),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  }
}
