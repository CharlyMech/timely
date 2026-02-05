/// Manages application environment configuration and build flavors.
///
/// Provides access to the current environment flavor (dev/firebase/api) and
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
/// print(Environment.flavor); // 'dev', 'firebase', or 'api'
/// ```
///
/// Data sources: dev → mock, firebase → Firebase, api → REST API.
/// To build with a specific flavor:
/// ```bash
/// flutter run --dart-define=FLAVOR=dev
/// flutter run --dart-define=FLAVOR=firebase
/// flutter run --dart-define=FLAVOR=api --dart-define=API_URL=http://localhost:3000/api
/// ```
class Environment {
  /// The compile-time constant key used to read the environment flavor.
  static const String _flavorKey = 'FLAVOR';

  /// The compile-time constant key used to read the API URL.
  static const String _apiUrlKey = 'API_URL';

  /// Returns the current environment flavor.
  ///
  /// Defaults to 'dev' if no flavor is specified at compile time.
  static String get flavor {
    return const String.fromEnvironment(_flavorKey, defaultValue: 'dev');
  }

  /// Returns the API URL for API mode.
  ///
  /// Returns an empty string if not specified at compile time.
  /// Should only be used when [isApi] is true.
  static String get apiUrl {
    return const String.fromEnvironment(_apiUrlKey, defaultValue: '');
  }

  /// Returns `true` if the app is running in development mode (mock).
  static bool get isDev => flavor == 'dev';

  /// Returns `true` if the app is running in Firebase mode.
  static bool get isFirebase => flavor == 'firebase';

  /// Returns `true` if the app is running in API mode (REST API).
  static bool get isApi => flavor == 'api';

  /// Returns `true` if the API URL is configured.
  static bool get hasApiUrl => apiUrl.isNotEmpty;
}
