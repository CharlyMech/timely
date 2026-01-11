import 'package:timely/models/shift.dart';

// Interface
abstract class ShiftService {
  Future<List<Shift>> getEmployeeShifts(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10});

  Future<Shift?> getTodayShift(String employeeId);

  Future<int> getMonthlyShiftsCount(String employeeId, DateTime month);

  Future<List<Shift>> getMonthlyShifts(String employeeId, DateTime month);

  Future<Shift> createShift(Shift shift);

  Future<Shift> updateShift(Shift shift);

  Future<void> deleteShift(String shiftId);
}
