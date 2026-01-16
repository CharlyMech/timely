import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/services/config_service.dart';

/// Firebase implementation of [ConfigService].
///
/// Manages application configuration using Firestore's 'settings' collection.
/// Provides in-memory caching to minimize database reads for frequently
/// accessed configuration data.
class FirebaseConfigService implements ConfigService {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// Document ID for the app configuration in Firestore.
  final String _docId = 'app_config';

  /// In-memory cache for the configuration to minimize database reads.
  AppConfig? _cachedConfig;

  /// Creates a new Firebase config service.
  ///
  /// Optionally accepts a custom [firestore] instance for testing purposes.
  /// Defaults to [FirebaseFirestore.instance] if not provided.
  FirebaseConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppConfig> getConfig() async {
    // Return cached config if available to minimize Firestore reads
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final doc = await _firestore.collection('settings').doc(_docId).get();

      if (!doc.exists) {
        // Initialize with default config if none exists in Firestore
        final defaultConfig = AppConfig.defaultConfig();
        await updateConfig(defaultConfig);
        return defaultConfig;
      }

      _cachedConfig = AppConfig.fromJson(doc.data()!);
      return _cachedConfig!;
    } catch (e) {
      throw Exception('Error al cargar configuración desde Firebase: $e');
    }
  }

  @override
  Future<void> updateConfig(AppConfig config) async {
    try {
      await _firestore
          .collection('settings')
          .doc(_docId)
          .set(config.toJson(), SetOptions(merge: true));
      // Update cache to reflect the new configuration
      _cachedConfig = config;
    } catch (e) {
      throw Exception('Error al actualizar configuración en Firebase: $e');
    }
  }
}
