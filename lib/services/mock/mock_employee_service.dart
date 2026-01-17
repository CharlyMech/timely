import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';

/// Mock implementation of [EmployeeService] for testing and development.
///
/// Loads employee data from a local JSON file (assets/mock/employees.json)
/// instead of a remote database. Provides in-memory caching and simulated
/// network delays for realistic testing.
class MockEmployeeService implements EmployeeService {
  /// In-memory cache for employees to simulate persistent storage.
  List<Employee>? _cachedEmployees;

  /// Random generator for realistic network delay simulation.
  final _random = Random();

  /// Simulates network delay with random variation.
  Future<void> _simulateDelay(int minMs, int maxMs) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  @override
  Future<List<Employee>> getEmployees() async {
    // Return cached employees if available
    if (_cachedEmployees != null) {
      return _cachedEmployees!;
    }

    // Simulate network delay (loading employee list with profile data)
    await _simulateDelay(600, 1200);

    try {
      // Load employees from asset bundle
      final String response = await rootBundle.loadString(
        'assets/mock/employees.json',
      );
      final List<dynamic> data = json.decode(response);
      _cachedEmployees = data.map((json) => Employee.fromJson(json)).toList();
      return _cachedEmployees!;
    } catch (e) {
      debugPrint('Error loading mock employees: $e');
      return [];
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    // Load all employees from cache or JSON, then find by ID
    final employees = await getEmployees();
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    // Simulate network delay (write operation with validation)
    await _simulateDelay(500, 900);
    // Update employee in cache if it exists
    if (_cachedEmployees != null) {
      final index = _cachedEmployees!.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _cachedEmployees![index] = employee;
      }
    }
  }
}
