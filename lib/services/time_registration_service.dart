import 'package:timely/models/time_registration.dart';

/// Service interface for managing employee time registrations.
///
/// Defines the contract for tracking work hours including starting,
/// ending, pausing, and resuming workdays. Supports querying historical
/// registrations by date ranges and provides optimized count methods.
abstract class TimeRegistrationService {
  /// Retrieves today's time registration for a specific employee.
  ///
  /// Returns the [TimeRegistration] for the current day, or null if
  /// no registration exists. Used to determine if an employee has
  /// already started their workday.
  Future<TimeRegistration?> getTodayRegistration(String employeeId);

  /// Starts a new workday for an employee.
  ///
  /// Creates a new time registration with the current timestamp as the
  /// start time. Associates the registration with the specified [shiftId].
  ///
  /// Throws [Exception] if a registration for today already exists.
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId);

  /// Ends the current workday.
  ///
  /// Sets the end time to the current timestamp for the registration
  /// identified by [registrationId].
  ///
  /// Throws [Exception] if the workday has already been ended.
  Future<TimeRegistration> endWorkday(String registrationId);

  /// Pauses the current workday.
  ///
  /// Sets the pause time to the current timestamp for the registration
  /// identified by [registrationId]. Used to track break periods.
  ///
  /// Throws [Exception] if the workday is already paused.
  Future<TimeRegistration> pauseWorkday(String registrationId);

  /// Resumes a paused workday.
  ///
  /// Sets the resume time to the current timestamp for the registration
  /// identified by [registrationId].
  ///
  /// Throws [Exception] if the workday is not paused or has already been resumed.
  Future<TimeRegistration> resumeWorkday(String registrationId);

  /// Retrieves paginated employee registrations.
  ///
  /// Returns a list of [TimeRegistration] records for the specified
  /// [employeeId], sorted by start time in descending order (most recent first).
  /// Supports pagination via [limit] (default: 100) and [offset] (default: 0).
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  });

  /// Counts total registrations for an employee.
  ///
  /// Returns the total count of all time registrations for the specified
  /// [employeeId]. Optimized to avoid loading full registration data.
  Future<int> getTotalRegistrationsCount(String employeeId);

  /// Retrieves all registrations for a specific month.
  ///
  /// Returns a list of [TimeRegistration] records for the specified
  /// [employeeId] within the given [month]. Results are sorted by
  /// start time in descending order.
  Future<List<TimeRegistration>> getMonthlyRegistrations(
    String employeeId,
    DateTime month,
  );

  /// Counts registrations for a specific month.
  ///
  /// Returns the total count of registrations for the specified [employeeId]
  /// within the given [month]. Optimized to avoid loading full registration data.
  Future<int> getMonthlyRegistrationsCount(String employeeId, DateTime month);

  /// Retrieves today's registrations for all employees in a single query.
  ///
  /// Returns a map where keys are employee IDs and values are their
  /// [TimeRegistration] for today. Employees without a registration
  /// are not included in the map.
  ///
  /// This is optimized to reduce N+1 query problems when loading
  /// multiple employees at once.
  Future<Map<String, TimeRegistration>> getAllTodayRegistrations();

  /// Retrieves a single time registration by ID.
  Future<TimeRegistration?> getRegistrationById(String registrationId);

  /// Retrieves the current active (not ended) registration for an employee, if any.
  Future<TimeRegistration?> getActiveRegistration(String employeeId);

  /// Retrieves all active (not ended) time registrations across employees.
  Future<List<TimeRegistration>> getAllActiveRegistrations();

  /// Adds a note to a time registration.
  Future<void> addNoteToRegistration(String registrationId, String note);

  /// Closes a registration by setting end time to now (if not already ended).
  Future<TimeRegistration> autoCloseRegistration(String registrationId);
}
