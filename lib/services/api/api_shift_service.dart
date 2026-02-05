import 'package:timely/models/shift.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/utils/timezone_utils.dart';

/// API implementation of [ShiftService].
class ApiShiftService implements ShiftService {
  ApiShiftService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  static String _dateToIso(DateTime d) => d.toUtc().toIso8601String();

  @override
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'employeeId': employeeId,
      'limit': limit,
    };
    if (startDate != null) query['startDate'] = _dateToIso(startDate);
    if (endDate != null) query['endDate'] = _dateToIso(endDate);
    final res = await _client.get('$_prefix/shifts', queryParams: query);
    if (!res.success) throw Exception(res.error ?? 'Error al cargar turnos');
    final raw = res.data!['data'] ?? res.data!['shifts'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) return [];
    return list
        .map((e) => Shift.fromJson(_toMap(e)))
        .toList();
  }

  static Map<String, dynamic> _toMap(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return Map<String, dynamic>.from(e);
    throw ArgumentError('Expected map, got ${e.runtimeType}');
  }

  @override
  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10}) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return getEmployeeShifts(
      employeeId,
      startDate: today,
      limit: limit,
    );
  }

  @override
  Future<Shift?> getTodayShift(String employeeId) async {
    final list = await getUpcomingShifts(employeeId, limit: 1);
    if (list.isEmpty) return null;
    final first = list.first;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (first.date.year == today.year &&
        first.date.month == today.month &&
        first.date.day == today.day) {
      return first;
    }
    return null;
  }

  @override
  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month) async {
    final list = await getMonthlyShifts(employeeId, month);
    return list.length;
  }

  @override
  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getEmployeeShifts(employeeId, startDate: start, endDate: end, limit: 100);
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    final body = {
      'id': shift.id,
      'employeeId': shift.employeeId,
      'date': _dateToIso(TimezoneUtils.toUtcForStorage(shift.date)),
      'shiftTypeId': shift.shiftTypeId,
      'notes': shift.notes,
    };
    final res = await _client.post('$_prefix/shifts', body: body);
    if (!res.success) throw Exception(res.error ?? 'Error al crear turno');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) throw Exception('Respuesta inválida');
    return Shift.fromJson(map);
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    final body = {
      'employeeId': shift.employeeId,
      'date': _dateToIso(TimezoneUtils.toUtcForStorage(shift.date)),
      'shiftTypeId': shift.shiftTypeId,
      'notes': shift.notes,
    };
    final res = await _client.put('$_prefix/shifts/${shift.id}', body: body);
    if (!res.success) throw Exception(res.error ?? 'Error al actualizar turno');
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return shift;
    return Shift.fromJson(map);
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    final res = await _client.delete('$_prefix/shifts/$shiftId');
    if (!res.success) throw Exception(res.error ?? 'Error al eliminar turno');
  }

  @override
  Future<Shift?> getShiftById(String shiftId) async {
    final res = await _client.get('$_prefix/shifts/$shiftId');
    if (!res.success) return null;
    final raw = res.data!['data'] ?? res.data;
    final map = raw is Map<String, dynamic> ? raw : null;
    if (map == null) return null;
    return Shift.fromJson(map);
  }

  @override
  Future<Map<String, Shift>> getAllTodayShifts() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow = today.add(const Duration(days: 1));
    final res = await _client.get('$_prefix/shifts', queryParams: {
      'startDate': _dateToIso(today),
      'endDate': _dateToIso(tomorrow),
      'limit': 500,
    });
    if (!res.success) throw Exception(res.error ?? 'Error al cargar turnos de hoy');
    final raw = res.data!['data'] ?? res.data!['shifts'] ?? res.data;
    final list = raw is List ? raw : null;
    if (list == null) return {};
    final map = <String, Shift>{};
    for (final e in list) {
      final shift = Shift.fromJson(_toMap(e));
      map[shift.employeeId] = shift;
    }
    return map;
  }
}
