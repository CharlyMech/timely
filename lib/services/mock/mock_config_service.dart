import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/services/config_service.dart';

/// Mock implementation of [ConfigService] for testing and development.
///
/// Loads configuration from a local JSON file (assets/mock/config.json)
/// instead of a remote database. Provides in-memory caching and simulated
/// network delays for realistic testing.
class MockConfigService implements ConfigService {
  /// In-memory cache for the configuration to simulate persistent storage.
  AppConfig? _cachedConfig;

  @override
  Future<AppConfig> getConfig() async {
    // Return cached config if available
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Load config from asset bundle
      final String response =
          await rootBundle.loadString('assets/mock/config.json');
      final data = json.decode(response) as Map<String, dynamic>;
      _cachedConfig = AppConfig.fromJson(data);
      return _cachedConfig!;
    } catch (e) {
      // Fallback to default config if JSON file is missing
      _cachedConfig = AppConfig.defaultConfig();
      return _cachedConfig!;
    }
  }

  @override
  Future<void> updateConfig(AppConfig config) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // Update in-memory cache (not persisted to file in mock implementation)
    _cachedConfig = config;
  }
}
