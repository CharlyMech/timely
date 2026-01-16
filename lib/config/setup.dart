import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles application initialization and setup tasks.
///
/// Provides utility methods for initializing app dependencies and
/// accessing system-level information.
class AppSetup {
  /// Cached instance of [SharedPreferences].
  static SharedPreferences? _prefs;

  /// Initializes and returns the [SharedPreferences] instance.
  ///
  /// Uses a singleton pattern to ensure only one instance is created.
  /// Should be called during app initialization before accessing preferences.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   final prefs = await AppSetup.initializePreferences();
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Returns the initialized [SharedPreferences] instance.
  static Future<SharedPreferences> initializePreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Returns the current system brightness setting.
  ///
  /// Useful for determining if the device is in light or dark mode
  /// at the system level.
  ///
  /// Returns [Brightness.light] or [Brightness.dark].
  static Brightness getSystemBrightness() {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}
