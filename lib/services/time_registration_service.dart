import 'package:timely/models/time_registration.dart';

// Interface
abstract class TimeRegistrationService {
  Future<TimeRegistration?> getTodayRegistration(String employeeId);
  Future<TimeRegistration> startWorkday(String employeeId, String shiftId);
  Future<TimeRegistration> endWorkday(String registrationId);
  Future<TimeRegistration> pauseWorkday(String registrationId);
  Future<TimeRegistration> resumeWorkday(String registrationId);
  Future<List<TimeRegistration>> getEmployeeRegistrations(
    String employeeId, {
    int limit = 100,
    int offset = 0,
  });
  Future<int> getTotalRegistrationsCount(String employeeId);
}
