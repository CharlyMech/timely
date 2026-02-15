/// Template for environment configuration.
///
/// A single [Env] in env.dart holds all variables for every mode (dev, firebase, api).
/// Copy this file to env.dart and replace placeholders with your values.
/// Do not commit env.dart (add to .gitignore).
///
/// ## Run
///
/// ```bash
/// flutter run --dart-define=FLAVOR=dev
/// flutter run --dart-define=FLAVOR=firebase
/// flutter run --dart-define=FLAVOR=api
/// ```
/// With FLAVOR=api, baseUrl defaults to http://localhost:3000 unless API_URL is set.
///
/// ## Structure (single Env class)
///
/// - **Shared**: [inactivityTimeoutMinutes] (all flavors)
/// - **Firebase**: used when FLAVOR=firebase (projectId, androidApiKey, iosApiKey, etc.)
/// - **API**: used when FLAVOR=api ([baseUrl], [appId], [appToken], [timeoutSeconds])
library;

// ignore_for_file: unused_element

/// Example env with full structure. Copy to env.dart.
abstract class EnvExample {
  static const int inactivityTimeoutMinutes = 5;

  static const String messagingSenderId = 'PROJECT_SENDER_ID';
  static const String projectId = 'PROJECT_ID';
  static const String storageBucket = 'PROJECT_STORAGE_BUCKET';
  static const String androidApiKey = 'ANDROID_API_KEY';
  static const String androidAppId = 'ANDROID_APP_ID';
  static const String androidMessagingSenderId = messagingSenderId;
  static const String androidProjectId = projectId;
  static const String androidStorageBucket = storageBucket;
  static const String iosApiKey = 'IOS_API_KEY';
  static const String iosAppId = 'IOS_APP_ID';
  static const String iosMessagingSenderId = messagingSenderId;
  static const String iosProjectId = projectId;
  static const String iosStorageBucket = storageBucket;
  static const String iosBundleId = 'com.example.app';

  static const String baseUrl = 'http://localhost:3000';
  static const String appId = 'timely-demo';
  static const String appToken = 'app_xxx';
  static const int timeoutSeconds = 30;
}
