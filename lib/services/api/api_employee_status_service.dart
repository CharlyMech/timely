import 'package:timely/models/employee_status.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/employee_status_service.dart';

/// API implementation of [EmployeeStatusService].
class ApiEmployeeStatusService implements EmployeeStatusService {
  ApiEmployeeStatusService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<List<EmployeeStatus>> getAllStatuses() async {
    final res = await _client.get('$_prefix/employee-statuses');
    if (!res.success) throw Exception(res.error ?? 'Error al cargar estados');
    final data = res.data!['data'] ?? res.data;
    final list = data is List ? data : null;
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => EmployeeStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EmployeeStatus?> getStatusById(String id) async {
    final res = await _client.get('$_prefix/employee-statuses/$id');
    if (!res.success) return null;
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return null;
    return EmployeeStatus.fromJson(map);
  }

  @override
  Future<EmployeeStatus?> getStatusByCode(String status) async {
    final list = await getAllStatuses();
    try {
      return list.firstWhere((s) => s.status == status);
    } catch (_) {
      return null;
    }
  }
}
