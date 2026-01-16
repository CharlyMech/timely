import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/services/shift_type_service.dart';

/// Mock implementation of [ShiftTypeService] for testing and development.
///
/// Loads shift type data from a local JSON file (assets/mock/shift_types.json)
/// instead of a remote database. Provides in-memory caching and simulated
/// network delays for realistic testing.
class MockShiftTypeService implements ShiftTypeService {
  /// In-memory cache for shift types to simulate persistent storage.
  List<ShiftType>? _cachedShiftTypes;

  @override
  Future<List<ShiftType>> getAllShiftTypes() async {
    // Return cached shift types if available
    if (_cachedShiftTypes != null) {
      return _cachedShiftTypes!;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      // Load shift types from asset bundle
      final String response =
          await rootBundle.loadString('assets/mock/shift_types.json');
      final data = json.decode(response) as List<dynamic>;
      _cachedShiftTypes = data
          .map((json) => ShiftType.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedShiftTypes!;
    } catch (e) {
      // Return empty list if JSON file is missing
      _cachedShiftTypes = [];
      return _cachedShiftTypes!;
    }
  }

  @override
  Future<ShiftType?> getShiftTypeById(String id) async {
    // Load all shift types from cache or JSON, then find by ID
    final shiftTypes = await getAllShiftTypes();
    try {
      return shiftTypes.firstWhere((st) => st.id == id);
    } catch (e) {
      return null;
    }
  }
}
