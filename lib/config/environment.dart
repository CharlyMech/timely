/// Manages application environment configuration and build flavors.
///
/// Provides access to the current environment flavor (dev/prod) and
/// utility methods to check which environment the app is running in.
///
/// The flavor is determined by compile-time environment variables:
///
/// ```dart
/// // Check current environment
/// if (Environment.isDev) {
///   print('Running in development mode');
/// }
///
/// // Get the flavor name
/// print(Environment.flavor); // 'dev' or 'prod'
/// ```
///
/// To build with a specific flavor:
/// ```bash
/// flutter run --dart-define=FLAVOR=prod
/// ```
class Environment {
  /// The compile-time constant key used to read the environment flavor.
  static const String _flavorKey = 'FLAVOR';

  /// Returns the current environment flavor.
  ///
  /// Defaults to 'dev' if no flavor is specified at compile time.
  static String get flavor {
    return const String.fromEnvironment(_flavorKey, defaultValue: 'dev');
  }

  /// Returns `true` if the app is running in development mode.
  static bool get isDev => flavor == 'dev';

  /// Returns `true` if the app is running in production mode.
  static bool get isProd => flavor == 'prod';
}
