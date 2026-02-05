import 'package:timely/models/role.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/role_service.dart';

/// API implementation of [RoleService].
class ApiRoleService implements RoleService {
  ApiRoleService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<List<Role>> getAllRoles() async {
    final res = await _client.get('$_prefix/roles');
    if (!res.success) throw Exception(res.error ?? 'Error al cargar roles');
    final data = res.data!['data'] ?? res.data;
    final list = data is List ? data : null;
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => Role.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Role?> getRoleById(String id) async {
    final res = await _client.get('$_prefix/roles/$id');
    if (!res.success) return null;
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return null;
    return Role.fromJson(map);
  }
}
