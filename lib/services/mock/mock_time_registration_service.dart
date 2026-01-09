import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class MockTimeRegistrationService implements TimeRegistrationService {
  final List<TimeRegistration> _registrations = [];
  final List<TimeRegistration> _historicalRegistrations = [];
  final _uuid = const Uuid();
  bool _historicalDataInitialized = false;

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    try {
      return _registrations.firstWhere(
        (reg) => reg.employeeId == employeeId && reg.date == today,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    final today = DateFormat('dd/MM/yyyy').format(now);

    final registration = TimeRegistration(
      id: _uuid.v4(),
      employeeId: employeeId,
      shiftId: shiftId,
      startTime: now,
      date: today,
    );

    _registrations.add(registration);
    return registration;
  }

  @override
  Future<TimeRegistration> endWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _registrations.indexWhere((reg) => reg.id == registrationId);

    if (index == -1) {
      throw Exception('Registration not found');
    }

    final updated = _registrations[index].copyWith(endTime: DateTime.now());
    _registrations[index] = updated;
    return updated;
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _registrations.indexWhere((reg) => reg.id == registrationId);

    if (index == -1) {
      throw Exception('Registration not found');
    }

    if (_registrations[index].pauseTime != null) {
      throw Exception('Workday is already paused');
    }

    final updated = _registrations[index].copyWith(pauseTime: DateTime.now());
    _registrations[index] = updated;
    return updated;
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _registrations.indexWhere((reg) => reg.id == registrationId);

    if (index == -1) {
      throw Exception('Registration not found');
    }

    if (_registrations[index].pauseTime == null) {
      throw Exception('Workday is not paused');
    }

    if (_registrations[index].resumeTime != null) {
      throw Exception('Workday has already been resumed');
    }

    final updated = _registrations[index].copyWith(resumeTime: DateTime.now());
    _registrations[index] = updated;
    return updated;
  }

  void _initializeHistoricalData() {
    if (_historicalDataInitialized) return;

    // Generate historical data for each employee
    final employeeIds = [
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890', // Carlos
      'b2c3d4e5-f6a7-8901-bcde-f12345678901', // María
      'c3d4e5f6-a7b8-9012-cdef-123456789012', // Juan
      'd4e5f6a7-b8c9-0123-def1-234567890123', // Ana
      'e5f6a7b8-c9d0-1234-ef12-345678901234', // Luis
      'f6a7b8c9-d0e1-2345-f123-456789012345', // Elena
    ];

    final random = DateTime.now().millisecondsSinceEpoch % 100;

    for (var employeeId in employeeIds) {
      // Generate data for December 2025 (all work days)
      final daysInDecember = 31;

      for (var day = 1; day <= daysInDecember; day++) {
        final workDate = DateTime(2025, 12, day);

        // Skip weekends
        if (workDate.weekday == DateTime.saturday ||
            workDate.weekday == DateTime.sunday) {
          continue;
        }

        // Vary start times between 8:00 and 9:30
        final startHour = 8;
        final startMinute = ((random + day) % 90);
        final startTime = DateTime(
          workDate.year,
          workDate.month,
          workDate.day,
          startHour,
          startMinute,
        );

        // Vary work duration between 6h45m and 8h15m
        final durationMinutes = 405 + ((random + day * 2) % 90);
        final endTime = startTime.add(Duration(minutes: durationMinutes));

        _historicalRegistrations.add(
          TimeRegistration(
            id: _uuid.v4(),
            employeeId: employeeId,
            shiftId: 'mock-shift-${workDate.year}-${workDate.month}-${workDate.day}',
            startTime: startTime,
            endTime: endTime,
            date: DateFormat('dd/MM/yyyy').format(workDate),
          ),
        );
      }

      // Add some data from previous months (November and October 2025)
      for (var month = 10; month <= 11; month++) {
        final daysInMonth = month == 10 ? 31 : 30;
        for (var day = 1; day <= daysInMonth; day++) {
          final workDate = DateTime(2025, month, day);

          if (workDate.weekday == DateTime.saturday ||
              workDate.weekday == DateTime.sunday) {
            continue;
          }

          final startHour = 8;
          final startMinute = ((random + day + month) % 90);
          final startTime = DateTime(
            workDate.year,
            workDate.month,
            workDate.day,
            startHour,
            startMinute,
          );

          final durationMinutes = 405 + ((random + day * 2 + month) % 90);
          final endTime = startTime.add(Duration(minutes: durationMinutes));

          _historicalRegistrations.add(
            TimeRegistration(
              id: _uuid.v4(),
              employeeId: employeeId,
              shiftId: 'mock-shift-${workDate.year}-${workDate.month}-${workDate.day}',
              startTime: startTime,
              endTime: endTime,
              date: DateFormat('dd/MM/yyyy').format(workDate),
            ),
          );
        }
      }
    }

    // Sort by date descending (most recent first)
    _historicalRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));
    _historicalDataInitialized = true;
  }

  @override
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    _initializeHistoricalData();
    await Future.delayed(const Duration(milliseconds: 500));

    final employeeRegs = _historicalRegistrations
        .where((reg) => reg.employeeId == employeeId)
        .toList();

    final start = offset.clamp(0, employeeRegs.length);
    final end = (offset + limit).clamp(0, employeeRegs.length);

    return employeeRegs.sublist(start, end);
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    _initializeHistoricalData();
    await Future.delayed(const Duration(milliseconds: 100));

    return _historicalRegistrations
        .where((reg) => reg.employeeId == employeeId)
        .length;
  }
}
