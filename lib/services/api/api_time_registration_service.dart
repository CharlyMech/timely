import 'package:timely/models/time_registration.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/timezone_utils.dart';

/// API implementation of [TimeRegistrationService].
class ApiTimeRegistrationService implements TimeRegistrationService {
  ApiTimeRegistrationService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  /// URL for time registrations of a specific employee.
  /// GET employees/:id/time-registrations — query params:
  /// - [date] DD/MM/YYYY: filter by day (takes precedence over range)
  /// - [startDate]/[endDate] ISO: range when date is not sent
  /// - [limit]/[offset]: pagination
  String _employeeRegistrationsUrl(String employeeId) =>
      '$_prefix/employees/$employeeId/time-registrations';

  static String _dateTimeToIso(DateTime d) =>
      TimezoneUtils.toUtcForStorage(d).toUtc().toIso8601String();

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    final today = DateTimeUtils.getTodayFormatted(); // DD/MM/YYYY
    final res = await _client.get(
      _employeeRegistrationsUrl(employeeId),
      queryParams: {'date': today},
    );
    if (!res.success) return null;
    final raw = res.data!['data'] ?? res.data!['timeRegistrations'] ?? res.data;
    if (raw is List && raw.isNotEmpty) {
      return TimeRegistration.fromJson(_toMap(raw.first));
    }
    if (raw is Map<String, dynamic>) {
      return TimeRegistration.fromJson(raw);
    }
    if (raw is Map) {
      return TimeRegistration.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  @override
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId) async {
    final res = await _client.post('$_prefix/time-registrations/start', body: {
      'employeeId': employeeId,
      'shiftId': shiftId,
    });
    if (!res.success) throw Exception(res.error ?? 'Error al iniciar jornada');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) throw Exception('Respuesta inválida');
    return TimeRegistration.fromJson(map);
  }

  @override
  Future<TimeRegistration> endWorkday(String registrationId) async {
    final res = await _client.post(
      '$_prefix/time-registrations/$registrationId/end',
      body: <String, dynamic>{},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al finalizar jornada');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) throw Exception('Respuesta inválida');
    return TimeRegistration.fromJson(map);
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    final res = await _client.post(
      '$_prefix/time-registrations/$registrationId/pause',
      body: <String, dynamic>{},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al pausar jornada');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) throw Exception('Respuesta inválida');
    return TimeRegistration.fromJson(map);
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    final res = await _client.post(
      '$_prefix/time-registrations/$registrationId/resume',
      body: <String, dynamic>{},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al reanudar jornada');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) throw Exception('Respuesta inválida');
    return TimeRegistration.fromJson(map);
  }

  @override
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _client.get(
      _employeeRegistrationsUrl(employeeId),
      queryParams: {'limit': limit, 'offset': offset},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al cargar registros');
    final raw = res.data!['data'] ?? res.data!['timeRegistrations'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) return [];
    return list
        .map((e) => TimeRegistration.fromJson(_toMap(e)))
        .toList();
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    final res = await _client.get(
      '$_prefix/time-registrations/count',
      queryParams: {'employeeId': employeeId},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al contar registros');
    final data = res.data!['data'] ?? res.data;
    if (data is Map && data['count'] != null) return data['count'] as int;
    if (data is int) return data;
    return 0;
  }

  @override
  Future<List<TimeRegistration>> getMonthlyRegistrations(
    String employeeId,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final res = await _client.get(
      _employeeRegistrationsUrl(employeeId),
      queryParams: {
        'startDate': _dateTimeToIso(start),
        'endDate': _dateTimeToIso(end),
      },
    );
    if (!res.success) throw Exception(res.error ?? 'Error al cargar registros mensuales');
    final raw = res.data!['data'] ?? res.data!['timeRegistrations'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) return [];
    return list
        .map((e) => TimeRegistration.fromJson(_toMap(e)))
        .toList();
  }

  static Map<String, dynamic> _toMap(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return Map<String, dynamic>.from(e);
    throw ArgumentError('Expected map, got ${e.runtimeType}');
  }

  @override
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month) async {
    final list = await getMonthlyRegistrations(employeeId, month);
    return list.length;
  }

  @override
  Future<Map<String, TimeRegistration>> getAllTodayRegistrations() async {
    final today = DateTimeUtils.getTodayFormatted();
    final res = await _client.get('$_prefix/time-registrations', queryParams: {
      'date': today,
      'limit': 500,
    });
    if (!res.success) throw Exception(res.error ?? 'Error al cargar registros de hoy');
    final raw = res.data!['data'] ?? res.data!['timeRegistrations'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) return {};
    final map = <String, TimeRegistration>{};
    for (final e in list) {
      final reg = TimeRegistration.fromJson(_toMap(e));
      map[reg.employeeId] = reg;
    }
    return map;
  }

  @override
  Future<TimeRegistration?> getRegistrationById(String registrationId) async {
    final res = await _client.get('$_prefix/time-registrations/$registrationId');
    if (!res.success) return null;
    final raw = res.data!['data'] ?? res.data;
    final map = raw is Map<String, dynamic> ? raw : null;
    if (map == null) return null;
    return TimeRegistration.fromJson(map);
  }

  @override
  Future<TimeRegistration?> getActiveRegistration(String employeeId) async {
    final today = await getTodayRegistration(employeeId);
    if (today == null || !today.isActive) return null;
    return today;
  }

  @override
  Future<List<TimeRegistration>> getAllActiveRegistrations() async {
    final allToday = await getAllTodayRegistrations();
    return allToday.values.where((r) => r.isActive).toList();
  }

  @override
  Future<void> addNoteToRegistration(String registrationId, String note) async {
    final res = await _client.post(
      '$_prefix/notes',
      body: {'timeRegistrationId': registrationId, 'content': note},
    );
    if (!res.success) throw Exception(res.error ?? 'Error al añadir nota');
  }

  @override
  Future<TimeRegistration> autoCloseRegistration(String registrationId) async {
    return endWorkday(registrationId);
  }
}
