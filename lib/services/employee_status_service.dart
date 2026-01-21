import 'package:timely/models/employee_status.dart';

/// Service interface for managing employee statuses.
///
/// Defines the contract for retrieving employee status definitions including
/// names, descriptions, and associated colors.
abstract class EmployeeStatusService {
  /// Retrieves all available employee statuses in the system.
  ///
  /// Returns a list of all [EmployeeStatus] records. Implementations may use
  /// caching to optimize repeated calls since statuses rarely change.
  Future<List<EmployeeStatus>> getAllStatuses();

  /// Retrieves a specific employee status by its unique identifier.
  ///
  /// Returns the [EmployeeStatus] with the given [id], or null if not found.
  Future<EmployeeStatus?> getStatusById(String id);

  /// Retrieves a specific employee status by its status code.
  ///
  /// Returns the [EmployeeStatus] with the given [status] code (e.g., 'active'),
  /// or null if not found.
  Future<EmployeeStatus?> getStatusByCode(String status);
}
