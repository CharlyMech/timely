import 'dart:convert';
import 'package:flutter/services.dart';
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

  Future<void> _initializeHistoricalData() async {
    if (_historicalDataInitialized) return;

    try {
      // Load data from JSON file
      final String jsonString = await rootBundle.loadString('assets/mock/time_registrations.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // Parse all registrations from JSON
      for (var item in jsonData) {
        final registration = TimeRegistration.fromJson(item);
        _historicalRegistrations.add(registration);
      }

      // Sort by date descending (most recent first)
      _historicalRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));
      _historicalDataInitialized = true;
    } catch (e) {
      print('Error loading time registrations from JSON: $e');
      // Fallback to empty list if JSON loading fails
      _historicalDataInitialized = true;
    }
  }

  @override
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    await _initializeHistoricalData();
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
    await _initializeHistoricalData();
    await Future.delayed(const Duration(milliseconds: 100));

    return _historicalRegistrations
        .where((reg) => reg.employeeId == employeeId)
        .length;
  }
}
