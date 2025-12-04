import 'package:timely/models/employee.dart';

/// Interface
abstract class EmployeeService {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<void> updateEmployee(Employee employee);
}
