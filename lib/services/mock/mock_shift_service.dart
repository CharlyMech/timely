import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/services/shift_service.dart';

class MockShiftService implements ShiftService {
  // Cache de turnos por mes (key: 'YYYY-MM', value: lista de turnos del mes)
  // Esto simula una caché local, pero los datos se cargan del JSON por mes
  final Map<String, List<Shift>> _shiftsByMonth = {};

  /// Obtiene la clave del mes en formato 'YYYY-MM'
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Carga SOLO los turnos de un mes específico desde el JSON
  /// Simula una query a Firebase: db.collection('shifts').where('month', '==', 'YYYY-MM')
  Future<List<Shift>> _loadShiftsForMonth(DateTime month) async {
    final monthKey = _getMonthKey(month);

    // Si ya está en caché, devolver del caché
    if (_shiftsByMonth.containsKey(monthKey)) {
      return _shiftsByMonth[monthKey]!;
    }

    try {
      // Cargar TODO el JSON (esto es solo por limitación de mock con archivos)
      final String response = await rootBundle.loadString('assets/mock/shifts.json');
      final List<dynamic> data = json.decode(response);

      // IMPORTANTE: En Firebase, esta query sería:
      // await FirebaseFirestore.instance
      //   .collection('shifts')
      //   .where('year', isEqualTo: month.year)
      //   .where('month', isEqualTo: month.month)
      //   .get();

      // Filtrar SOLO los turnos del mes solicitado
      final monthShifts = data
          .map((json) => Shift.fromJson(json))
          .where((shift) =>
              shift.date.year == month.year &&
              shift.date.month == month.month)
          .toList();

      monthShifts.sort((a, b) => a.date.compareTo(b.date));

      // Guardar en caché local
      _shiftsByMonth[monthKey] = monthShifts;

      return monthShifts;
    } catch (e) {
      _shiftsByMonth[monthKey] = [];
      return [];
    }
  }

  /// Carga un rango de meses (uno por uno)
  Future<void> _loadMonthRangeIfNeeded(DateTime startDate, DateTime endDate) async {
    // Iterar mes a mes desde startDate hasta endDate
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      await _loadShiftsForMonth(current);
      // Avanzar al siguiente mes
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
    // Si se especifica un rango, cargar solo esos meses
    if (startDate != null && endDate != null) {
      await _loadMonthRangeIfNeeded(startDate, endDate);
    } else {
      // Sin rango específico, cargar los últimos 3 meses como fallback
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        await _loadShiftsForMonth(month);
      }
    }

    // Recopilar turnos de los meses cargados
    List<Shift> allLoadedShifts = [];
    for (var monthShifts in _shiftsByMonth.values) {
      allLoadedShifts.addAll(monthShifts);
    }

    var filtered = allLoadedShifts.where((shift) => shift.employeeId == employeeId);

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
  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Cargar SOLO el mes actual y los próximos 2 meses
    await _loadShiftsForMonth(now);
    await _loadShiftsForMonth(DateTime(now.year, now.month + 1, 1));
    await _loadShiftsForMonth(DateTime(now.year, now.month + 2, 1));

    // Recopilar turnos de los meses cargados
    List<Shift> allLoadedShifts = [];
    for (var monthShifts in _shiftsByMonth.values) {
      allLoadedShifts.addAll(monthShifts);
    }

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

    // Cargar SOLO el mes actual
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
    // Cargar SOLO el mes solicitado
    final monthShifts = await _loadShiftsForMonth(month);

    return monthShifts
        .where((shift) => shift.employeeId == employeeId)
        .length;
  }

  @override
  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month) async {
    // Cargar SOLO el mes solicitado
    final monthShifts = await _loadShiftsForMonth(month);

    return monthShifts
        .where((shift) => shift.employeeId == employeeId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Asegurarse de que el mes del turno esté cargado
    await _loadShiftsForMonth(shift.date);

    final monthKey = _getMonthKey(shift.date);
    if (_shiftsByMonth.containsKey(monthKey)) {
      _shiftsByMonth[monthKey]!.add(shift);
      _shiftsByMonth[monthKey]!.sort((a, b) => a.date.compareTo(b.date));
    }

    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    await Future.delayed(const Duration(milliseconds: 500));

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
    await Future.delayed(const Duration(milliseconds: 500));

    // Buscar y eliminar en todos los meses cargados
    for (var monthShifts in _shiftsByMonth.values) {
      monthShifts.removeWhere((shift) => shift.id == shiftId);
    }
  }
}
