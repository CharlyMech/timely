class Environment {
  static const String _flavorKey = 'FLAVOR';

  static String get flavor {
    return const String.fromEnvironment(_flavorKey, defaultValue: 'dev');
  }

  static bool get isDev => flavor == 'dev';
  static bool get isProd => flavor == 'prod';
}
