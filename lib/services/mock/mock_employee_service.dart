import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';

class MockEmployeeService implements EmployeeService {
  List<Employee>? _cachedEmployees;

  @override
  Future<List<Employee>> getEmployees() async {
    if (_cachedEmployees != null) {
      return _cachedEmployees!;
    }

    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final String response = await rootBundle.loadString(
        'assets/mock/employees.json',
      );
      final List<dynamic> data = json.decode(response);
      _cachedEmployees = data.map((json) => Employee.fromJson(json)).toList();
      return _cachedEmployees!;
    } catch (e) {
      print('Error loading mock employees: $e');
      return [];
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final employees = await getEmployees();
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_cachedEmployees != null) {
      final index = _cachedEmployees!.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _cachedEmployees![index] = employee;
      }
    }
  }
}
