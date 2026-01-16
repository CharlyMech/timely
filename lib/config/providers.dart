import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/config/environment.dart';
import 'package:timely/repositories/employee_repository.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/time_registration_service.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/services/config_service.dart';
import 'package:timely/services/shift_type_service.dart';
import 'package:timely/services/role_service.dart';
import 'package:timely/services/mock/mock_employee_service.dart';
import 'package:timely/services/mock/mock_time_registration_service.dart';
import 'package:timely/services/mock/mock_shift_service.dart';
import 'package:timely/services/mock/mock_config_service.dart';
import 'package:timely/services/mock/mock_shift_type_service.dart';
import 'package:timely/services/mock/mock_role_service.dart';
import 'package:timely/services/firebase/firebase_employee_service.dart';
import 'package:timely/services/firebase/firebase_time_registration_service.dart';
import 'package:timely/services/firebase/firebase_shift_service.dart';
import 'package:timely/services/firebase/firebase_config_service.dart';
import 'package:timely/services/firebase/firebase_shift_type_service.dart';
import 'package:timely/services/firebase/firebase_role_service.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/models/role.dart';

/// Provides access to [SharedPreferences] instance.
///
/// This provider must be overridden in the application's [ProviderScope]
/// with an initialized [SharedPreferences] instance.
///
/// Example:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// ProviderScope(
///   overrides: [
///     sharedPreferencesProvider.overrideWithValue(prefs),
///   ],
///   child: MyApp(),
/// );
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Provides the [EmployeeService] implementation based on the current environment.
///
/// Returns [MockEmployeeService] in development mode and [FirebaseEmployeeService]
/// in production mode.
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

/// Provides the [TimeRegistrationService] implementation based on the current environment.
///
/// Returns [MockTimeRegistrationService] in development mode and
/// [FirebaseTimeRegistrationService] in production mode.
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((
  ref,
) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  } else {
    return FirebaseTimeRegistrationService();
  }
});

/// Provides the [ShiftService] implementation based on the current environment.
///
/// Returns [MockShiftService] in development mode and [FirebaseShiftService]
/// in production mode.
final shiftServiceProvider = Provider<ShiftService>((ref) {
  if (Environment.isDev) {
    return MockShiftService();
  } else {
    return FirebaseShiftService();
  }
});

/// Provides the [ConfigService] implementation based on the current environment.
///
/// Returns [MockConfigService] in development mode and [FirebaseConfigService]
/// in production mode.
final configServiceProvider = Provider<ConfigService>((ref) {
  if (Environment.isDev) {
    return MockConfigService();
  } else {
    return FirebaseConfigService();
  }
});

/// Provides the [ShiftTypeService] implementation based on the current environment.
///
/// Returns [MockShiftTypeService] in development mode and [FirebaseShiftTypeService]
/// in production mode.
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) {
  if (Environment.isDev) {
    return MockShiftTypeService();
  } else {
    return FirebaseShiftTypeService();
  }
});

/// Provides the [RoleService] implementation based on the current environment.
///
/// Returns [MockRoleService] in development mode and [FirebaseRoleService]
/// in production mode.
final roleServiceProvider = Provider<RoleService>((ref) {
  if (Environment.isDev) {
    return MockRoleService();
  } else {
    return FirebaseRoleService();
  }
});

/// Provides the application configuration.
///
/// Fetches and caches the [AppConfig] from the [ConfigService].
/// This is a [FutureProvider] that loads asynchronously.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});

/// Provides the list of all available shift types.
///
/// Fetches and caches all [ShiftType] entries from the [ShiftTypeService].
/// This is a [FutureProvider] that loads asynchronously.
final shiftTypesProvider = FutureProvider<List<ShiftType>>((ref) async {
  final shiftTypeService = ref.watch(shiftTypeServiceProvider);
  return await shiftTypeService.getAllShiftTypes();
});

/// Provides the list of all available employee roles.
///
/// Fetches and caches all [Role] entries from the [RoleService].
/// This is a [FutureProvider] that loads asynchronously.
final rolesProvider = FutureProvider<List<Role>>((ref) async {
  final roleService = ref.watch(roleServiceProvider);
  return await roleService.getAllRoles();
});

/// Provides the [EmployeeRepository] with its required service dependencies.
///
/// Creates an [EmployeeRepository] instance configured with the appropriate
/// service implementations based on the current environment.
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
    shiftService: ref.watch(shiftServiceProvider),
  );
});
