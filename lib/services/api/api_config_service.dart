import 'package:timely/models/app_config.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/config_service.dart';

/// API implementation of [ConfigService].
class ApiConfigService implements ConfigService {
  ApiConfigService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<AppConfig> getConfig() async {
    final res = await _client.get('$_prefix/config');
    if (!res.success) throw Exception(res.error ?? 'Error al cargar configuración');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return AppConfig.defaultConfig();
    return AppConfig.fromJson(map);
  }

  @override
  Future<void> updateConfig(AppConfig config) async {
    final res = await _client.put('$_prefix/config', body: config.toJson());
    if (!res.success) throw Exception(res.error ?? 'Error al actualizar configuración');
  }
}
