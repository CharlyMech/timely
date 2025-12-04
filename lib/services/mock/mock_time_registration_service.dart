import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class MockTimeRegistrationService implements TimeRegistrationService {
  final List<TimeRegistration> _registrations = [];
  final _uuid = const Uuid();

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
  Future<TimeRegistration> startWorkday(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    final today = DateFormat('dd/MM/yyyy').format(now);

    final registration = TimeRegistration(
      id: _uuid.v4(),
      employeeId: employeeId,
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
  Future<List<TimeRegistration>> getRegistrationsByDate(String date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _registrations.where((reg) => reg.date == date).toList();
  }
}
