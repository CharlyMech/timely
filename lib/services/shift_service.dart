import 'package:timely/models/shift.dart';

/// Service interface for managing employee work shifts.
///
/// Defines the contract for creating, retrieving, updating, and deleting
/// shift assignments. Supports querying shifts by date ranges, specific
/// months, and provides optimized methods for common queries.
abstract class ShiftService {
  /// Retrieves employee shifts within an optional date range.
  ///
  /// Returns a list of [Shift] records for the specified [employeeId].
  /// Optionally filters by [startDate] and [endDate], and limits results
  /// to [limit] records (default: 50).
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  /// Retrieves upcoming shifts for an employee starting from today.
  ///
  /// Returns a list of future [Shift] records for the specified [employeeId],
  /// limited to [limit] records (default: 10). Results are sorted by date
  /// in ascending order.
  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10});

  /// Retrieves today's shift for a specific employee.
  ///
  /// Returns the [Shift] assigned for the current day, or null if no
  /// shift is scheduled for today.
  Future<Shift?> getTodayShift(String employeeId);

  /// Counts the number of shifts in a specific month.
  ///
  /// Returns the total count of shifts for the specified [employeeId]
  /// within the given [month]. This is optimized to avoid loading
  /// full shift data when only a count is needed.
  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month);

  /// Retrieves all shifts for a specific month.
  ///
  /// Returns a list of [Shift] records for the specified [employeeId]
  /// within the given [month]. Results are sorted by date in ascending order.
  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month);

  /// Creates a new shift assignment.
  ///
  /// Persists the provided [shift] to the data source. If [Shift.id] is
  /// empty, a new unique ID will be generated. Returns the created shift
  /// with its assigned ID.
  Future<Shift> createShift(Shift shift);

  /// Updates an existing shift assignment.
  ///
  /// Persists changes to the provided [shift]. The shift must already
  /// exist (identified by [Shift.id]). Returns the updated shift.
  Future<Shift> updateShift(Shift shift);

  /// Deletes a shift assignment.
  ///
  /// Permanently removes the shift with the specified [shiftId] from
  /// the data source.
  Future<void> deleteShift(String shiftId);
}
