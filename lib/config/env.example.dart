/// Template for environment configuration.
///
/// All env files (env.api.dart, env.firebase.dart, env.mock.dart) share the
/// same structure; each fills in only its specific values (Firebase params,
/// API params, or shared params like [inactivityTimeoutMinutes]).
///
/// ## Setup
///
/// 1. Copy this file to env.dart, env.api.dart, env.firebase.dart, env.mock.dart as needed.
/// 2. Replace placeholders with your values.
/// 3. Do not commit env files (they are in .gitignore).
///
/// ## Run
///
/// ```bash
/// flutter run --dart-define=FLAVOR=dev
/// flutter run --dart-define=FLAVOR=api [--dart-define=API_URL=http://localhost:3000/api]
/// flutter run --dart-define=FLAVOR=firebase
/// ```
///
/// ## Structure (same in all env files)
///
/// - **Shared**: [inactivityTimeoutMinutes]
/// - **Firebase** (used when FLAVOR=firebase): projectId, androidApiKey, iosApiKey, etc.
/// - **API** (used when FLAVOR=api): [baseUrl], [appId], [appToken], [timeoutSeconds]
library;

// ignore_for_file: unused_element

/// Example env with full structure. Copy to env.dart / env.api.dart / env.firebase.dart / env.mock.dart.
abstract class EnvExample {
  // ---------- Shared (all flavors) ----------
  static const int inactivityTimeoutMinutes = 5;

  // ---------- Firebase (FLAVOR=firebase) ----------
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

  // ---------- API (FLAVOR=api) ----------
  static const String baseUrl = 'http://localhost:3000/api';
  static const String appId = 'timely-demo';
  static const String appToken = 'app_xxx'; // x-app-token header
  static const int timeoutSeconds = 30;
}
