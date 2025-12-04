import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/config/environment.dart';

class AppSetup {
  static SharedPreferences? _prefs;

  /// Inicializa SharedPreferences
  static Future<SharedPreferences> initializePreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Obtiene el brightness del sistema
  static Brightness getSystemBrightness() {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  /// Log de configuración inicial
  static void logConfiguration() {
    if (kDebugMode) {
      print('========================================');
      print('🚀 Timely App Configuration');
      print('========================================');
      print('Environment: ${Environment.flavor}');
      print('isDev: ${Environment.isDev}');
      print('isProd: ${Environment.isProd}');
      print('========================================');
    }
  }
}
