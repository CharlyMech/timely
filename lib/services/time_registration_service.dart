import 'package:timely/models/time_registration.dart';

// Interface
abstract class TimeRegistrationService {
  Future<TimeRegistration?> getTodayRegistration(String employeeId);
  Future<TimeRegistration> startWorkday(String employeeId);
  Future<TimeRegistration> endWorkday(String registrationId);
  Future<List<TimeRegistration>> getRegistrationsByDate(String date);
}
