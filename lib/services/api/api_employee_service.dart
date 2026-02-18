import 'package:flutter/foundation.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/employee_service.dart';

/// API implementation of [EmployeeService].
class ApiEmployeeService implements EmployeeService {
  ApiEmployeeService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<List<Employee>> getEmployees({
    int page = 1,
    int limit = 100,
    bool withRelations = false,
  }) async {
    final url = '$_prefix/employees';
    debugPrint(
      '[ApiEmployeeService] getEmployees() GET $url?page=$page&limit=$limit&withRelations=$withRelations',
    );
    final res = await _client.get(
      url,
      queryParams: {
        'page': page,
        'limit': limit,
        'withRelations': withRelations,
      },
    );
    debugPrint('=====');
    debugPrint(res.data.toString());
    debugPrint('=====');
    debugPrint(
      '[ApiEmployeeService] getEmployees() response: success=${res.success} statusCode=${res.statusCode}',
    );

    if (!res.success) {
      debugPrint('[ApiEmployeeService] getEmployees() FAILED: ${res.error}');
      throw Exception(res.error ?? 'Error al cargar empleados');
    }

    // Response: { data: Employee[] } or { items: Employee[] } or direct list
    final raw = res.data!['data'] ?? res.data!['items'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) {
      debugPrint(
        '[ApiEmployeeService] getEmployees() ERROR: raw is not a list, type=${raw.runtimeType}',
      );
      return [];
    }

    debugPrint(
      '[ApiEmployeeService] getEmployees() received ${list.length} employees from API',
    );

    // With withRelations=true the API embeds currentRegistration and todayShift
    // (full objects or IDs). Employee.fromJson parses nested maps into objects.
    final employees = <Employee>[];
    for (var i = 0; i < list.length; i++) {
      try {
        final empJson = _toMap(list[i]);
        final employee = Employee.fromJson(empJson);
        employees.add(employee);
      } catch (e, stack) {
        debugPrint(
          '[ApiEmployeeService] getEmployees() ERROR parsing employee $i: $e',
        );
        debugPrint('[ApiEmployeeService] Stack: $stack');
        debugPrint('[ApiEmployeeService] Employee data: ${list[i]}');
      }
    }

    debugPrint(
      '[ApiEmployeeService] getEmployees() successfully parsed ${employees.length} employees',
    );
    return employees;
  }

  static Map<String, dynamic> _toMap(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return Map<String, dynamic>.from(e);
    throw ArgumentError('Expected map, got ${e.runtimeType}');
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
    if (!res.success) {
      throw Exception(res.error ?? 'Error al actualizar empleado');
    }
  }
}
