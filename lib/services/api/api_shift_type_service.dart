import 'package:timely/models/shift_type.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/shift_type_service.dart';

/// API implementation of [ShiftTypeService].
class ApiShiftTypeService implements ShiftTypeService {
  ApiShiftTypeService(this._client);

  final ApiClient _client;
  String get _prefix => _client.config.companiesPrefix;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    final res = await _client.get('$_prefix/shift-types');
    if (!res.success) throw Exception(res.error ?? 'Error al cargar tipos de turno');
    final data = res.data!['data'] ?? res.data;
    final list = data is List ? data : null;
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => ShiftType.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<ShiftType?> getShiftTypeById(String id) async {
    final res = await _client.get('$_prefix/shift-types/$id');
    if (!res.success) return null;
    final data = res.data!['data'] ?? res.data;
    final map = data is Map<String, dynamic> ? data : null;
    if (map == null) return null;
    return ShiftType.fromJson(map);
  }
}
