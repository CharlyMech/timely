import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/services/shift_service.dart';

/// Mock implementation of [ShiftService] for testing and development.
///
/// Loads shift data from a local JSON file (assets/mock/shifts.json) with
/// month-based lazy loading and caching.
/// Each month's data is loaded on-demand and cached in memory.
class MockShiftService implements ShiftService {
  /// Month-based cache (key: 'YYYY-MM', value: list of shifts for that month).
  ///
  /// Only requested months are loaded on-demand.
  final Map<String, List<Shift>> _shiftsByMonth = {};

  /// Random generator for realistic network delay simulation.
  final _random = Random();

  /// Simulates network delay with random variation.
  Future<void> _simulateDelay(int minMs, int maxMs) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Generates a month key in 'YYYY-MM' format for cache indexing.
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Loads shifts for a specific month from JSON and caches them.
  ///
  /// Returns cached data if already loaded for the given month.
  Future<List<Shift>> _loadShiftsForMonth(DateTime month) async {
    final monthKey = _getMonthKey(month);

    // Return from cache if already loaded
    if (_shiftsByMonth.containsKey(monthKey)) {
      return _shiftsByMonth[monthKey]!;
    }

    // Simulate network delay (querying shifts by month)
    await _simulateDelay(400, 800);

    try {
      // Load entire JSON (limitation of mock with file-based data)
      final String response = await rootBundle.loadString('assets/mock/shifts.json');
      final List<dynamic> data = json.decode(response);

      // Filter to only shifts in the requested month
      final monthShifts = data
          .map((json) => Shift.fromJson(json))
          .where((shift) =>
              shift.date.year == month.year &&
              shift.date.month == month.month)
          .toList();

      // Sort by date ascending
      monthShifts.sort((a, b) => a.date.compareTo(b.date));

      // Cache for future requests
      _shiftsByMonth[monthKey] = monthShifts;

      return monthShifts;
    } catch (e) {
      _shiftsByMonth[monthKey] = [];
      return [];
    }
  }

  /// Loads a range of months (one by one) if not already cached.
  ///
  /// Iterates month by month from [startDate] to [endDate] and loads
  /// each month's data individually.
  Future<void> _loadMonthRangeIfNeeded(DateTime startDate, DateTime endDate) async {
    // Iterate month by month from startDate to endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      await _loadShiftsForMonth(current);
      // Advance to next month
      current = DateTime(current.year, current.month + 1, 1);
    }
  }

  @override
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    // Load specific month range if dates provided, otherwise load last 3 months
    if (startDate != null && endDate != null) {
      await _loadMonthRangeIfNeeded(startDate, endDate);
    } else {
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        await _loadShiftsForMonth(month);
      }
    }

    // Collect shifts from all loaded months
    List<Shift> allLoadedShifts = [];
    for (var monthShifts in _shiftsByMonth.values) {
      allLoadedShifts.addAll(monthShifts);
    }

    // Filter by employee ID
    var filtered = allLoadedShifts.where((shift) => shift.employeeId == employeeId);

    // Apply date filters if provided
    if (startDate != null) {
      filtered = filtered.where((shift) =>
          shift.date.isAfter(startDate) ||
          shift.date.isAtSameMomentAs(startDate));
    }

    if (endDate != null) {
      filtered = filtered.where((shift) =>
          shift.date.isBefore(endDate) || shift.date.isAtSameMomentAs(endDate));
    }

    // Sort and limit results
    final result = filtered.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return result.take(limit).toList();
  }

  @override
  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load current month and next 2 months for upcoming shifts
    await _loadShiftsForMonth(now);
    await _loadShiftsForMonth(DateTime(now.year, now.month + 1, 1));
    await _loadShiftsForMonth(DateTime(now.year, now.month + 2, 1));

    // Collect shifts from loaded months
    List<Shift> allLoadedShifts = [];
    for (var monthShifts in _shiftsByMonth.values) {
      allLoadedShifts.addAll(monthShifts);
    }

    // Filter for upcoming shifts (today and future)
    final upcoming = allLoadedShifts
        .where((shift) =>
            shift.employeeId == employeeId &&
            (shift.date.isAfter(today) || shift.isToday))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming.take(limit).toList();
  }

  @override
  Future<Shift?> getTodayShift(String employeeId) async {
    final now = DateTime.now();

    // Load only current month
    final monthShifts = await _loadShiftsForMonth(now);

    try {
      return monthShifts.firstWhere((shift) =>
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
    // Load only the requested month
    final monthShifts = await _loadShiftsForMonth(month);

    return monthShifts
        .where((shift) => shift.employeeId == employeeId)
        .length;
  }

  @override
  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month) async {
    // Load only the requested month
    final monthShifts = await _loadShiftsForMonth(month);

    return monthShifts
        .where((shift) => shift.employeeId == employeeId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    // Simulate network delay (write operation)
    await _simulateDelay(500, 900);

    // Ensure the shift's month is loaded
    await _loadShiftsForMonth(shift.date);

    // Add to appropriate month cache
    final monthKey = _getMonthKey(shift.date);
    if (_shiftsByMonth.containsKey(monthKey)) {
      _shiftsByMonth[monthKey]!.add(shift);
      _shiftsByMonth[monthKey]!.sort((a, b) => a.date.compareTo(b.date));
    }

    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    // Simulate network delay (write operation)
    await _simulateDelay(500, 900);

    // Update in the appropriate month cache
    final monthKey = _getMonthKey(shift.date);
    if (_shiftsByMonth.containsKey(monthKey)) {
      final monthShifts = _shiftsByMonth[monthKey]!;
      final index = monthShifts.indexWhere((s) => s.id == shift.id);
      if (index != -1) {
        monthShifts[index] = shift;
      }
    }

    return shift;
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    // Simulate network delay (delete operation)
    await _simulateDelay(400, 800);

    // Search and remove from all loaded months
    for (var monthShifts in _shiftsByMonth.values) {
      monthShifts.removeWhere((shift) => shift.id == shiftId);
    }
  }

  @override
  Future<Shift?> getShiftById(String shiftId) async {
    await _simulateDelay(200, 400);
    for (var monthShifts in _shiftsByMonth.values) {
      try {
        return monthShifts.firstWhere((s) => s.id == shiftId);
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<Map<String, Shift>> getAllTodayShifts() async {
    final now = DateTime.now();

    // Load only current month
    final monthShifts = await _loadShiftsForMonth(now);

    final Map<String, Shift> shiftsByEmployee = {};

    for (final shift in monthShifts) {
      if (shift.date.year == now.year &&
          shift.date.month == now.month &&
          shift.date.day == now.day) {
        shiftsByEmployee[shift.employeeId] = shift;
      }
    }

    return shiftsByEmployee;
  }
}
