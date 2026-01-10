import 'package:flutter/material.dart';
import '../constants/themes.dart';

class ColorUtils {
  static const Color redColor = Color(0xFFD64C4C);
  static const Color orangeColor = Color(0xFFFFAB2E);
  static const Color greenColor = Color(0xFF46B56C);
  static const Color primaryColor = Color(0xFFEFCC80);
  static const Color onRedColor = Color(0xFFFFFFFF);
  static const Color greyColor = Colors.grey;

  static Color get redColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorRed);
  }

  static Color get orangeColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorOrange);
  }

  static Color get greenColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.colorGreen);
  }

  static Color get primaryColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.primaryColor);
  }

  static Color get onRedColorFromTheme {
    return _colorFromHex(themes[ThemeType.light]!.onRedColor);
  }

  static Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
