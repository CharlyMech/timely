import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/services/config_service.dart';

class MockConfigService implements ConfigService {
  AppConfig? _cachedConfig;

  @override
  Future<AppConfig> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final String response =
          await rootBundle.loadString('assets/mock/config.json');
      final data = json.decode(response) as Map<String, dynamic>;
      _cachedConfig = AppConfig.fromJson(data);
      return _cachedConfig!;
    } catch (e) {
      // If file doesn't exist or error loading, return default config
      _cachedConfig = AppConfig.defaultConfig();
      return _cachedConfig!;
    }
  }

  @override
  Future<void> updateConfig(AppConfig config) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cachedConfig = config;
    // In a real implementation, this would persist to a file or API
  }
}
