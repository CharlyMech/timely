enum ThemeType { light, dark, system }

class MyTheme {
  final String primaryColor;
  final String onPrimaryColor;
  final String backgroundColor;
  final String onBackgroundColor;
  final String surfaceColor;
  final String onSurfaceColor;
  final String colorGreen;
  final String colorRed;
  final String onRedColor;
  final String colorOrange;
  final String inactiveColor;
  final String onInactiveColor;
  final String outlineColor;
  final String shadow;

  const MyTheme({
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.colorGreen,
    required this.colorRed,
    required this.onRedColor,
    required this.colorOrange,
    required this.inactiveColor,
    required this.onInactiveColor,
    required this.outlineColor,
    required this.shadow,
  });
}

const Map<ThemeType, MyTheme> themes = {
  ThemeType.light: MyTheme(
    primaryColor: "#EFCC80",
    onPrimaryColor: "#333333",
    backgroundColor: "#F3F3F3",
    onBackgroundColor: "#333333",
    surfaceColor: "#FAFAFA",
    onSurfaceColor: "#333333",
    colorGreen: "#46B56C",
    colorRed: "#D64C4C",
    onRedColor: "#FFFFFF",
    colorOrange: "#FFAB2E",
    inactiveColor: "#D0D0D0",
    onInactiveColor: "#1f1f1f",
    outlineColor: "#EEEEEE",
    shadow: "#000000",
  ),
  ThemeType.dark: MyTheme(
    primaryColor: "#EFCC80",
    onPrimaryColor: "#333333",
    backgroundColor: "#121212",
    onBackgroundColor: "#E6E7EB",
    surfaceColor: "#1f1f1f",
    onSurfaceColor: "#E6E7EB",
    colorGreen: "#46B56C",
    colorRed: "#D64C4C",
    onRedColor: "#FFFFFF",
    colorOrange: "#FFAB2E",
    inactiveColor: "#5E5E5E",
    onInactiveColor: "#E6E7EB",
    outlineColor: "#EEEEEE",
    shadow: "#D0D0D0",
  ),
};
