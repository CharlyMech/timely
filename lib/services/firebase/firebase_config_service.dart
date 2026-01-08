import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/services/config_service.dart';

class FirebaseConfigService implements ConfigService {
  final FirebaseFirestore _firestore;
  final String _docId = 'app_config';
  AppConfig? _cachedConfig;

  FirebaseConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppConfig> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final doc = await _firestore.collection('config').doc(_docId).get();

      if (!doc.exists) {
        // If config doesn't exist in Firebase, create default and return it
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
          .collection('config')
          .doc(_docId)
          .set(config.toJson(), SetOptions(merge: true));
      _cachedConfig = config;
    } catch (e) {
      throw Exception('Error al actualizar configuración en Firebase: $e');
    }
  }
}
