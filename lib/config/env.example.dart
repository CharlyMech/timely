// INSTRUCTIONS:
// 1. Copy this file to env.dart (in the same directory)
// 2. Replace the example values ​​with your actual Firebase credentials
// 3. NEVER commit the env.dart file (it must be in .gitignore)

class FirebaseEnv {
  // Shared values between platforms
  static const String messagingSenderId = 'PROJECT_SENDER_ID';
  static const String projectId = 'PROJECT_ID';
  static const String storageBucket = 'PROJECT_STORAGE_BUCKET';

  // Android
  static const String androidApiKey = 'ANDROID_API_KEY';
  static const String androidAppId = 'ANDROID_APP_ID';
  static const String androidMessagingSenderId = messagingSenderId;
  static const String androidProjectId = projectId;
  static const String androidStorageBucket = storageBucket;

  // iOS
  static const String iosApiKey = 'IOS_API_KEY';
  static const String iosAppId = 'IOS_APP_ID';
  static const String iosMessagingSenderId = messagingSenderId;
  static const String iosProjectId = projectId;
  static const String iosStorageBucket = storageBucket;
  static const String iosBundleId = 'com.example.app';
}
