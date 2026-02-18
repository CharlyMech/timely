import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Mock implementation of [TimeRegistrationService] for testing and development.
///
/// Loads time registration data from a local JSON file
/// (assets/mock/time_registrations.json) with month-based lazy loading and
/// caching. Supports full workday lifecycle
/// management with in-memory state updates.
class MockTimeRegistrationService implements TimeRegistrationService {
  /// Month-based cache (key: 'YYYY-MM', value: list of registrations for that month).
  ///
  /// Only requested months are loaded on-demand.
  final Map<String, List<TimeRegistration>> _registrationsByMonth = {};

  /// UUID generator for creating unique registration IDs.
  final _uuid = const Uuid();

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

  /// Loads registrations for a specific month from JSON and caches them.
  ///
  /// Returns cached data if already loaded for the given month.
  Future<List<TimeRegistration>> _loadRegistrationsForMonth(DateTime month) async {
    final monthKey = _getMonthKey(month);

    // Return from cache if already loaded
    if (_registrationsByMonth.containsKey(monthKey)) {
      return _registrationsByMonth[monthKey]!;
    }

    // Simulate network delay (querying registrations by month)
    await _simulateDelay(400, 800);

    try {
      // Load entire JSON (limitation of mock with file-based data)
      final String jsonString = await rootBundle.loadString('assets/mock/time_registrations.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // Filter to only registrations in the requested month
      final monthRegistrations = jsonData
          .map((item) => TimeRegistration.fromJson(item))
          .where((reg) =>
              reg.startTime.year == month.year &&
              reg.startTime.month == month.month)
          .toList();

      // Sort by start time descending (most recent first)
      monthRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Cache for future requests
      _registrationsByMonth[monthKey] = monthRegistrations;

      return monthRegistrations;
    } catch (e) {
      debugPrint('Error loading time registrations for month $monthKey: $e');
      _registrationsByMonth[monthKey] = [];
      return [];
    }
  }

  /// Searches for a registration by ID across all loaded months in cache.
  ///
  /// Returns null if the registration is not found in any loaded month.
  TimeRegistration? _findRegistrationById(String registrationId) {
    for (var monthRegs in _registrationsByMonth.values) {
      try {
        return monthRegs.firstWhere((reg) => reg.id == registrationId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Updates a registration in the cache or adds it if new.
  ///
  /// Maintains descending sort order (most recent first) after updating.
  void _updateRegistrationInCache(TimeRegistration registration) {
    final monthKey = _getMonthKey(registration.startTime);

    if (_registrationsByMonth.containsKey(monthKey)) {
      final monthRegs = _registrationsByMonth[monthKey]!;
      final index = monthRegs.indexWhere((r) => r.id == registration.id);

      if (index >= 0) {
        // Update existing registration
        monthRegs[index] = registration;
      } else {
        // Add new registration and maintain sort order
        monthRegs.add(registration);
        monthRegs.sort((a, b) => b.startTime.compareTo(a.startTime));
      }
    }
  }

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    // Simulate network delay (single document query)
    await _simulateDelay(300, 600);

    // Load only current month
    final now = DateTime.now();
    final monthRegs = await _loadRegistrationsForMonth(now);

    // Find registration matching today's date
    final today = DateFormat('dd/MM/yyyy').format(now);
    try {
      return monthRegs.firstWhere(
        (reg) => reg.employeeId == employeeId && reg.date == today,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId) async {
    // Simulate network delay (write operation)
    await _simulateDelay(600, 1000);
    final now = DateTime.now();
    final today = DateFormat('dd/MM/yyyy').format(now);

    // Create new registration with current timestamp
    final registration = TimeRegistration(
      id: _uuid.v4(),
      employeeId: employeeId,
      shiftId: shiftId,
      startTime: now,
      date: today,
    );

    // Ensure current month is loaded
    await _loadRegistrationsForMonth(now);

    // Add new registration to cache
    _updateRegistrationInCache(registration);

    return registration;
  }

  @override
  Future<TimeRegistration> endWorkday(String registrationId) async {
    // Simulate network delay (write operation)
    await _simulateDelay(600, 1000);

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    // Set end time to current timestamp
    final updated = registration.copyWith(endTime: DateTime.now());
    _updateRegistrationInCache(updated);

    return updated;
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    // Simulate network delay (write operation)
    await _simulateDelay(600, 1000);

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    // Validate not already paused
    if (registration.pauseTime != null) {
      throw Exception('Workday is already paused');
    }

    // Set pause time to current timestamp
    final updated = registration.copyWith(pauseTime: DateTime.now());
    _updateRegistrationInCache(updated);

    return updated;
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    // Simulate network delay (write operation)
    await _simulateDelay(600, 1000);

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    // Validate workday is paused
    if (registration.pauseTime == null) {
      throw Exception('Workday is not paused');
    }

    // Validate not already resumed
    if (registration.resumeTime != null) {
      throw Exception('Workday has already been resumed');
    }

    // Set resume time to current timestamp
    final updated = registration.copyWith(resumeTime: DateTime.now());
    _updateRegistrationInCache(updated);

    return updated;
  }

  @override
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    // Simulate network delay (paginated query)
    await _simulateDelay(500, 900);

    // Load last 12 months of registrations (legacy method)
    final now = DateTime.now();
    List<TimeRegistration> allRegs = [];

    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthRegs = await _loadRegistrationsForMonth(month);
      allRegs.addAll(monthRegs.where((reg) => reg.employeeId == employeeId));
    }

    // Sort by most recent first
    allRegs.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Apply pagination
    final start = offset.clamp(0, allRegs.length);
    final end = (offset + limit).clamp(0, allRegs.length);

    return allRegs.sublist(start, end);
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    // Simulate network delay (count aggregation)
    await _simulateDelay(200, 400);

    // Simulates a count aggregation query for the employee's registrations

    // Load last 12 months and count matching registrations
    final now = DateTime.now();
    int count = 0;

    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthRegs = await _loadRegistrationsForMonth(month);
      count += monthRegs.where((reg) => reg.employeeId == employeeId).length;
    }

    return count;
  }

  @override
  Future<List<TimeRegistration>> getMonthlyRegistrations(
    String employeeId,
    DateTime month,
  ) async {
    // Simulate network delay (monthly query)
    await _simulateDelay(400, 800);

    // Load only the requested month
    final monthRegs = await _loadRegistrationsForMonth(month);

    // Filter by employee ID
    return monthRegs
        .where((reg) => reg.employeeId == employeeId)
        .toList();
  }

  @override
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month) async {
    // Simulate network delay (count aggregation)
    await _simulateDelay(200, 400);

    // Load only the requested month
    final monthRegs = await _loadRegistrationsForMonth(month);

    // Count registrations for this employee
    return monthRegs
        .where((reg) => reg.employeeId == employeeId)
        .length;
  }

  @override
  Future<Map<String, TimeRegistration>> getAllTodayRegistrations() async {
    // Simulate network delay (batch query)
    await _simulateDelay(300, 600);

    final now = DateTime.now();
    final monthRegs = await _loadRegistrationsForMonth(now);

    final today = DateFormat('dd/MM/yyyy').format(now);
    final Map<String, TimeRegistration> registrationsByEmployee = {};

    for (final reg in monthRegs) {
      if (reg.date == today) {
        registrationsByEmployee[reg.employeeId] = reg;
      }
    }

    return registrationsByEmployee;
  }

  @override
  Future<TimeRegistration?> getRegistrationById(String registrationId) async {
    await _simulateDelay(200, 400);
    for (var regs in _registrationsByMonth.values) {
      try {
        return regs.firstWhere((r) => r.id == registrationId);
      } catch (_) {}
    }
    return null;
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
    await _simulateDelay(300, 500);
    // Mock: no-op (no notes storage in mock).
  }

  @override
  Future<TimeRegistration> autoCloseRegistration(String registrationId) async {
    return endWorkday(registrationId);
  }
}
