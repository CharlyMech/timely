import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/config/environment.dart';
import 'package:timely/repositories/employee_repository.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/services/mock/mock_employee_service.dart';
import 'package:timely/services/mock/mock_time_registration_service.dart';
import 'package:timely/services/firebase/firebase_employee_service.dart';
import 'package:timely/services/firebase/firebase_time_registration_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((
  ref,
) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  } else {
    return FirebaseTimeRegistrationService();
  }
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
  );
});
