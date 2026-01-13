import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class MockTimeRegistrationService implements TimeRegistrationService {
  // Cache de registros por mes (key: 'YYYY-MM', value: lista de registros del mes)
  // Esto simula una caché local, pero los datos se cargan del JSON por mes
  final Map<String, List<TimeRegistration>> _registrationsByMonth = {};
  final _uuid = const Uuid();

  /// Obtiene la clave del mes en formato 'YYYY-MM'
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Carga SOLO los registros de un mes específico desde el JSON
  /// Simula una query a Firebase: db.collection('registrations').where('month', '==', 'YYYY-MM')
  Future<List<TimeRegistration>> _loadRegistrationsForMonth(DateTime month) async {
    final monthKey = _getMonthKey(month);

    // Si ya está en caché, devolver del caché
    if (_registrationsByMonth.containsKey(monthKey)) {
      return _registrationsByMonth[monthKey]!;
    }

    try {
      // Cargar TODO el JSON (esto es solo por limitación de mock con archivos)
      final String jsonString = await rootBundle.loadString('assets/mock/time_registrations.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // IMPORTANTE: En Firebase, esta query sería:
      // await FirebaseFirestore.instance
      //   .collection('time_registrations')
      //   .where('year', isEqualTo: month.year)
      //   .where('month', isEqualTo: month.month)
      //   .get();

      // Filtrar SOLO los registros del mes solicitado
      final monthRegistrations = jsonData
          .map((item) => TimeRegistration.fromJson(item))
          .where((reg) =>
              reg.startTime.year == month.year &&
              reg.startTime.month == month.month)
          .toList();

      monthRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Guardar en caché local
      _registrationsByMonth[monthKey] = monthRegistrations;

      return monthRegistrations;
    } catch (e) {
      print('Error loading time registrations for month $monthKey: $e');
      _registrationsByMonth[monthKey] = [];
      return [];
    }
  }

  /// Busca un registro en los meses cargados en caché
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

  /// Actualiza un registro en la caché
  void _updateRegistrationInCache(TimeRegistration registration) {
    final monthKey = _getMonthKey(registration.startTime);

    if (_registrationsByMonth.containsKey(monthKey)) {
      final monthRegs = _registrationsByMonth[monthKey]!;
      final index = monthRegs.indexWhere((r) => r.id == registration.id);

      if (index >= 0) {
        monthRegs[index] = registration;
      } else {
        // Añadir nuevo registro y mantener ordenado
        monthRegs.add(registration);
        monthRegs.sort((a, b) => b.startTime.compareTo(a.startTime));
      }
    }
  }

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Cargar SOLO el mes actual
    final now = DateTime.now();
    final monthRegs = await _loadRegistrationsForMonth(now);

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

    // Asegurarse de que el mes actual esté cargado
    await _loadRegistrationsForMonth(now);

    // Añadir el nuevo registro al mes actual en caché
    _updateRegistrationInCache(registration);

    return registration;
  }

  @override
  Future<TimeRegistration> endWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    final updated = registration.copyWith(endTime: DateTime.now());
    _updateRegistrationInCache(updated);

    return updated;
  }

  @override
  Future<TimeRegistration> pauseWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    if (registration.pauseTime != null) {
      throw Exception('Workday is already paused');
    }

    final updated = registration.copyWith(pauseTime: DateTime.now());
    _updateRegistrationInCache(updated);

    return updated;
  }

  @override
  Future<TimeRegistration> resumeWorkday(String registrationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final registration = _findRegistrationById(registrationId);

    if (registration == null) {
      throw Exception('Registration not found');
    }

    if (registration.pauseTime == null) {
      throw Exception('Workday is not paused');
    }

    if (registration.resumeTime != null) {
      throw Exception('Workday has already been resumed');
    }

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
    await Future.delayed(const Duration(milliseconds: 500));

    // Este método es legacy y carga múltiples meses
    // En producción, podrías hacer paginación por fecha
    // Por ahora, cargar los últimos 12 meses
    final now = DateTime.now();
    List<TimeRegistration> allRegs = [];

    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthRegs = await _loadRegistrationsForMonth(month);
      allRegs.addAll(monthRegs.where((reg) => reg.employeeId == employeeId));
    }

    allRegs.sort((a, b) => b.startTime.compareTo(a.startTime));

    final start = offset.clamp(0, allRegs.length);
    final end = (offset + limit).clamp(0, allRegs.length);

    return allRegs.sublist(start, end);
  }

  @override
  Future<int> getTotalRegistrationsCount(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // En Firebase, esto sería un count query sin cargar documentos
    // await FirebaseFirestore.instance
    //   .collection('time_registrations')
    //   .where('employeeId', isEqualTo: employeeId)
    //   .count()
    //   .get();

    // Por ahora, cargar los últimos 12 meses para el count
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
    await Future.delayed(const Duration(milliseconds: 500));

    // Cargar SOLO el mes específico
    final monthRegs = await _loadRegistrationsForMonth(month);

    // Filtrar por empleado
    return monthRegs
        .where((reg) => reg.employeeId == employeeId)
        .toList();
  }

  @override
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Cargar SOLO el mes específico
    final monthRegs = await _loadRegistrationsForMonth(month);

    return monthRegs
        .where((reg) => reg.employeeId == employeeId)
        .length;
  }
}
