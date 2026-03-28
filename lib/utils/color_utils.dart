import 'package:flutter/material.dart';
import '../constants/themes.dart';

/// Utility class for color constants and theme color accessors.
///
/// Provides both static color constants and methods to retrieve colors
/// from the application theme configuration.
class ColorUtils {
  /// Standard red color for errors and critical states.
  static const Color redColor = Color(0xFFD64C4C);

  /// Standard orange color for warnings.
  static const Color orangeColor = Color(0xFFFFAB2E);

  /// Standard green color for success states.
  static const Color greenColor = Color(0xFF46B56C);

  /// Standard primary brand color.
  static const Color primaryColor = Color(0xFFEFCC80);

  /// Text color for content on red backgrounds.
  static const Color onRedColor = Color(0xFFFFFFFF);

  /// Standard grey color for disabled or inactive states.
  static const Color greyColor = Colors.grey;

  /// Returns the red color from the light theme configuration.
  static Color get redColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorRed);
  }

  /// Returns the orange color from the light theme configuration.
  static Color get orangeColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorOrange);
  }

  /// Returns the green color from the light theme configuration.
  static Color get greenColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorGreen);
  }

  /// Returns the primary color from the light theme configuration.
  static Color get primaryColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.primaryColor);
  }

  /// Returns the on-red color from the light theme configuration.
  static Color get onRedColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.onRedColor);
  }

  /// Parses a hex color string to a [Color] object.
  ///
  /// Accepts hex strings in the format '#RRGGBB'.
  /// The '#' is replaced with '0xff' for full opacity.
  ///
  /// Example:
  /// ```dart
  /// final color = ColorUtils.parseHexColor('#FF5733');
  /// ```
  static Color parseHexColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  }

  /// Parses a hex color string with a custom alpha value.
  ///
  /// [alpha] is a hex string like 'ee' or 'cc' representing the alpha channel.
  /// Defaults to 'ff' (fully opaque).
  ///
  /// Example:
  /// ```dart
  /// final color = ColorUtils.parseHexColorWithAlpha('#D0D0D0', 'ee');
  /// ```
  static Color parseHexColorWithAlpha(String hexColor, String alpha) {
    return Color(int.parse(hexColor.replaceFirst('#', '0x$alpha')));
  }

  /// Internal helper to convert a hex color string to a [Color].
  ///
  /// Removes the '#' prefix and prepends 'FF' for full opacity.
  static Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
