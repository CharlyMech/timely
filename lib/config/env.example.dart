/// Template for Firebase environment configuration.
///
/// This is a template class with placeholder values.
///
/// ## Setup Instructions
///
/// 1. Copy this file to `env.dart` in the same directory
/// 2. Replace the placeholder values with your actual Firebase credentials
/// 3. **NEVER commit the env.dart file** (it must be in .gitignore)
///
/// ## Getting Firebase Credentials
///
/// Obtain these values from your Firebase Console:
/// - Go to Project Settings > General
/// - Find your platform (Android/iOS) and copy the configuration values
///
/// See also:
/// - [env.dart] - The actual configuration file (not in version control)
/// - [DefaultFirebaseOptions] - Uses these values for Firebase initialization
class FirebaseEnv {
  // Shared values between platforms

  /// The Firebase Cloud Messaging sender ID used across all platforms.
  ///
  /// Replace with your project's messaging sender ID from Firebase Console.
  static const String messagingSenderId = 'PROJECT_SENDER_ID';

  /// The Firebase project identifier.
  ///
  /// Replace with your Firebase project ID.
  static const String projectId = 'PROJECT_ID';

  /// The Firebase storage bucket URL.
  ///
  /// Replace with your project's storage bucket address.
  static const String storageBucket = 'PROJECT_STORAGE_BUCKET';

  // Android

  /// The API key for Android platform authentication.
  ///
  /// Find this in Firebase Console under Android app configuration.
  static const String androidApiKey = 'ANDROID_API_KEY';

  /// The unique application identifier for Android.
  ///
  /// Find this in Firebase Console under Android app configuration.
  static const String androidAppId = 'ANDROID_APP_ID';

  /// The messaging sender ID for Android (references shared value).
  static const String androidMessagingSenderId = messagingSenderId;

  /// The project ID for Android (references shared value).
  static const String androidProjectId = projectId;

  /// The storage bucket for Android (references shared value).
  static const String androidStorageBucket = storageBucket;

  // iOS

  /// The API key for iOS platform authentication.
  ///
  /// Find this in Firebase Console under iOS app configuration.
  static const String iosApiKey = 'IOS_API_KEY';

  /// The unique application identifier for iOS.
  ///
  /// Find this in Firebase Console under iOS app configuration.
  static const String iosAppId = 'IOS_APP_ID';

  /// The messaging sender ID for iOS (references shared value).
  static const String iosMessagingSenderId = messagingSenderId;

  /// The project ID for iOS (references shared value).
  static const String iosProjectId = projectId;

  /// The storage bucket for iOS (references shared value).
  static const String iosStorageBucket = storageBucket;

  /// The iOS application bundle identifier.
  ///
  /// Replace with your iOS app's bundle ID (e.g., 'com.example.app').
  static const String iosBundleId = 'com.example.app';

  // App Configuration

  /// Idle time in minutes before returning to the home screen.
  ///
  /// When the user does not interact with the application during this time,
  /// it is automatically redirected to the splash screen to refresh the data.
  static const int inactivityTimeoutMinutes = 5;
}
