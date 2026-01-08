import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/config/environment.dart';
import 'package:timely/repositories/employee_repository.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/services/config_service.dart';
import 'package:timely/services/mock/mock_employee_service.dart';
import 'package:timely/services/mock/mock_time_registration_service.dart';
import 'package:timely/services/mock/mock_shift_service.dart';
import 'package:timely/services/mock/mock_config_service.dart';
import 'package:timely/services/firebase/firebase_employee_service.dart';
import 'package:timely/services/firebase/firebase_time_registration_service.dart';
import 'package:timely/services/firebase/firebase_shift_service.dart';
import 'package:timely/services/firebase/firebase_config_service.dart';
import 'package:timely/models/app_config.dart';

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

final shiftServiceProvider = Provider<ShiftService>((ref) {
  if (Environment.isDev) {
    return MockShiftService();
  } else {
    return FirebaseShiftService();
  }
});

final configServiceProvider = Provider<ConfigService>((ref) {
  if (Environment.isDev) {
    return MockConfigService();
  } else {
    return FirebaseConfigService();
  }
});

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
  );
});
