import 'package:timely/models/app_config.dart';

/// Service interface for managing application configuration.
///
/// Defines the contract for retrieving and updating app-wide configuration
/// settings such as target work times, thresholds, and working days.
abstract class ConfigService {
  /// Retrieves the current application configuration.
  ///
  /// Returns the [AppConfig] containing all application-wide settings.
  /// Implementations may use caching to optimize repeated calls.
  Future<AppConfig> getConfig();

  /// Updates the application configuration with new settings.
  ///
  /// Persists the provided [config] to the underlying storage mechanism
  /// (Firebase, local storage, etc.).
  Future<void> updateConfig(AppConfig config);
}
