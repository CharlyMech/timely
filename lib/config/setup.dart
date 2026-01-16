import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSetup {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> initializePreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Brightness getSystemBrightness() {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}
