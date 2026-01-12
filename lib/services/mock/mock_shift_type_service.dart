import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/services/shift_type_service.dart';

class MockShiftTypeService implements ShiftTypeService {
  List<ShiftType>? _cachedShiftTypes;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    if (_cachedShiftTypes != null) {
      return _cachedShiftTypes!;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final String response =
          await rootBundle.loadString('assets/mock/shift_types.json');
      final data = json.decode(response) as List<dynamic>;
      _cachedShiftTypes = data
          .map((json) => ShiftType.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedShiftTypes!;
    } catch (e) {
      // If file doesn't exist or error loading, return empty list
      _cachedShiftTypes = [];
      return _cachedShiftTypes!;
    }
  }

  @override
  Future<ShiftType?> getShiftTypeById(String id) async {
    final shiftTypes = await getAllShiftTypes();
    try {
      return shiftTypes.firstWhere((st) => st.id == id);
    } catch (e) {
      return null;
    }
  }
}
