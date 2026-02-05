import 'package:timely/models/employee.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/employee_service.dart';

/// API implementation of [EmployeeService].
class ApiEmployeeService implements EmployeeService {
  ApiEmployeeService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<List<Employee>> getEmployees() async {
    final res = await _client.get('$_prefix/employees');
    if (!res.success) throw Exception(res.error ?? 'Error al cargar empleados');
    final data = res.data!['data'] ?? res.data;
    final list = data is List ? data : null;
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final res = await _client.get('$_prefix/employees/$id');
    if (!res.success) return null;
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return null;
    return Employee.fromJson(map);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final res = await _client.put(
      '$_prefix/employees/${employee.id}',
      body: employee.toJson(),
    );
    if (!res.success) throw Exception(res.error ?? 'Error al actualizar empleado');
  }
}
