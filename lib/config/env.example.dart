/// Template for environment configuration.
///
/// Copy this file to env.dart and replace placeholders with your values.
/// Do not commit env.dart (add to .gitignore).
///
/// ## Run
///
/// ```bash
/// flutter run --dart-define=FLAVOR=dev
/// flutter run --dart-define=FLAVOR=api [--dart-define=API_URL=http://localhost:3000]
/// ```
///
/// ## Structure
///
/// - **Shared**: [inactivityTimeoutMinutes] (all flavors)
/// - **API**: used when FLAVOR=api ([baseUrl], [appId], [appToken], [timeoutSeconds])
library;

// ignore_for_file: unused_element

/// Example env with full structure. Copy to env.dart.
abstract class EnvExample {
  static const int inactivityTimeoutMinutes = 5;

  static const String baseUrl = 'http://localhost:3000';
  static const String appId = 'timely-demo';
  static const String appToken = 'app_xxx';
  static const int timeoutSeconds = 30;
}
