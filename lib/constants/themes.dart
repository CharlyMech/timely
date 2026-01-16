/// Defines the available theme types for the application.
///
/// - [light] - Light color scheme
/// - [dark] - Dark color scheme
/// - [system] - Follows system theme preference
enum ThemeType { light, dark, system }

/// Represents a custom theme configuration with color definitions.
///
/// Contains all color values needed for the application's visual styling,
/// including primary colors, surface colors, status colors, and their
/// corresponding on-colors for text and icons.
///
/// All colors are stored as hex strings (e.g., '#RRGGBB') and must be
/// parsed before use with Flutter's [Color] class.
class MyTheme {
  /// The primary brand color used for key UI elements.
  final String primaryColor;

  /// The color for text and icons on primary color backgrounds.
  final String onPrimaryColor;

  /// The main background color for screens and scaffolds.
  final String backgroundColor;

  /// The color for text and icons on background color.
  final String onBackgroundColor;

  /// The color for surface elements like cards and sheets.
  final String surfaceColor;

  /// The color for text and icons on surface color.
  final String onSurfaceColor;

  /// Success and positive status indicator color (green).
  final String colorGreen;

  /// Error and critical status indicator color (red).
  final String colorRed;

  /// The color for text and icons on red color backgrounds.
  final String onRedColor;

  /// Warning status indicator color (orange).
  final String colorOrange;

  /// Inactive or disabled element color.
  final String inactiveColor;

  /// The color for text and icons on inactive color backgrounds.
  final String onInactiveColor;

  /// Border and divider color.
  final String outlineColor;

  /// Shadow color for elevation effects.
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

/// Map of available themes keyed by [ThemeType].
///
/// Provides pre-configured light and dark theme instances.
/// Access themes using the [ThemeType] enum:
///
/// ```dart
/// final lightTheme = themes[ThemeType.light];
/// final darkTheme = themes[ThemeType.dark];
/// ```
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
