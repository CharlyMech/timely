import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/services/shift_service.dart';

class MockShiftService implements ShiftService {
  List<Shift>? _cachedShifts;

  Future<List<Shift>> _loadShifts() async {
    if (_cachedShifts != null) {
      return _cachedShifts!;
    }

    final String response =
        await rootBundle.loadString('assets/mock/shifts.json');
    final List<dynamic> data = json.decode(response);
    _cachedShifts = data.map((json) => Shift.fromJson(json)).toList();
    return _cachedShifts!;
  }

  @override
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final shifts = await _loadShifts();
    var filtered = shifts.where((shift) => shift.employeeId == employeeId);

    if (startDate != null) {
      filtered = filtered.where((shift) =>
          shift.date.isAfter(startDate) ||
          shift.date.isAtSameMomentAs(startDate));
    }

    if (endDate != null) {
      filtered = filtered.where((shift) =>
          shift.date.isBefore(endDate) || shift.date.isAtSameMomentAs(endDate));
    }

    final result = filtered.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result.take(limit).toList();
  }

  @override
  Future<List<Shift>> getUpcomingShifts(String employeeId,
      {int limit = 10}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final shifts = await _loadShifts();
    final upcoming = shifts
        .where((shift) =>
            shift.employeeId == employeeId &&
            (shift.date.isAfter(today) || shift.isToday))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming.take(limit).toList();
  }

  @override
  Future<Shift?> getTodayShift(String employeeId) async {
    final shifts = await _loadShifts();
    final now = DateTime.now();

    try {
      return shifts.firstWhere((shift) =>
          shift.employeeId == employeeId &&
          shift.date.year == now.year &&
          shift.date.month == now.month &&
          shift.date.day == now.day);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month) async {
    final shifts = await _loadShifts();
    return shifts
        .where((shift) =>
            shift.employeeId == employeeId &&
            shift.date.year == month.year &&
            shift.date.month == month.month)
        .length;
  }

  @override
  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month) async {
    final shifts = await _loadShifts();
    return shifts
        .where((shift) =>
            shift.employeeId == employeeId &&
            shift.date.year == month.year &&
            shift.date.month == month.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    // In a real implementation, this would create a new shift in the backend
    await Future.delayed(const Duration(milliseconds: 500));
    _cachedShifts?.add(shift);
    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    // In a real implementation, this would update the shift in the backend
    await Future.delayed(const Duration(milliseconds: 500));
    if (_cachedShifts != null) {
      final index = _cachedShifts!.indexWhere((s) => s.id == shift.id);
      if (index != -1) {
        _cachedShifts![index] = shift;
      }
    }
    return shift;
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    // In a real implementation, this would delete the shift from the backend
    await Future.delayed(const Duration(milliseconds: 500));
    _cachedShifts?.removeWhere((shift) => shift.id == shiftId);
  }
}
