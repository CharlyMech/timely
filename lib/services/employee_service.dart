import 'package:timely/models/employee.dart';

/// Service interface for managing employee data.
///
/// Defines the contract for retrieving and updating employee information
/// including personal details, contact info, and employment status.
abstract class EmployeeService {
  /// Retrieves all employees from the data source.
  ///
  /// Returns a list of all [Employee] records. The list may be empty
  /// if no employees exist.
  Future<List<Employee>> getEmployees();

  /// Retrieves a specific employee by their unique identifier.
  ///
  /// Returns the [Employee] with the given [id], or null if not found.
  Future<Employee?> getEmployeeById(String id);

  /// Updates an existing employee's information.
  ///
  /// Persists the changes in the provided [employee] to the data source.
  /// The employee must already exist (identified by [Employee.id]).
  Future<void> updateEmployee(Employee employee);
}
