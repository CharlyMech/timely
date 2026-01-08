import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/constants/themes.dart';

extension MyThemeToThemeData on MyTheme {
  ThemeData toThemeData() {
    final Color textColor = _parseColor(onBackgroundColor);

    return ThemeData(
      primaryColor: _parseColor(primaryColor),
      scaffoldBackgroundColor: _parseColor(backgroundColor),
      textTheme: TextTheme(
        // Titles and headings
        displayLarge: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        // Texts and labels
        bodyLarge: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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
