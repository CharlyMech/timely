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
import 'package:timely/services/employee_status_service.dart';
import 'package:timely/services/mock/mock_employee_service.dart';
import 'package:timely/services/mock/mock_time_registration_service.dart';
import 'package:timely/services/mock/mock_shift_service.dart';
import 'package:timely/services/mock/mock_config_service.dart';
import 'package:timely/services/mock/mock_shift_type_service.dart';
import 'package:timely/services/mock/mock_role_service.dart';
import 'package:timely/services/mock/mock_employee_status_service.dart';
import 'package:timely/services/firebase/firebase_employee_service.dart';
import 'package:timely/services/firebase/firebase_time_registration_service.dart';
import 'package:timely/services/firebase/firebase_shift_service.dart';
import 'package:timely/services/firebase/firebase_config_service.dart';
import 'package:timely/services/firebase/firebase_shift_type_service.dart';
import 'package:timely/services/firebase/firebase_role_service.dart';
import 'package:timely/services/firebase/firebase_employee_status_service.dart';
import 'package:timely/config/env.api.dart';
import 'package:timely/services/api/api_client.dart';
import 'package:timely/services/api/api_config_service.dart';
import 'package:timely/services/api/api_employee_service.dart';
import 'package:timely/services/api/api_shift_service.dart';
import 'package:timely/services/api/api_shift_type_service.dart';
import 'package:timely/services/api/api_time_registration_service.dart';
import 'package:timely/services/api/api_role_service.dart';
import 'package:timely/services/api/api_employee_status_service.dart';
import 'package:timely/services/api/api_auth_service.dart';
import 'package:timely/models/app_config.dart';
import 'package:timely/models/shift_type.dart';
import 'package:timely/models/role.dart';
import 'package:timely/models/employee_status.dart';

/// Provides access to [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Holds the current JWT after PIN login (API flavor). When set, [apiClientProvider] sends it as Bearer.
class ApiAuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) => state = token;
}

/// Current JWT after PIN login (API flavor). Set after successful POST /auth/pin; clear on logout or inactivity.
final apiAuthTokenProvider = NotifierProvider<ApiAuthTokenNotifier, String?>(ApiAuthTokenNotifier.new);

/// Provides the API client for API flavor. Uses [ApiEnv] and [apiAuthTokenProvider] for Bearer when set.
final apiClientProvider = Provider<ApiClient>((ref) {
  final token = Environment.isApi ? ref.watch(apiAuthTokenProvider) : null;
  return ApiClient(
    config: ApiConfig(
      baseUrl: ApiEnv.baseUrl,
      appId: ApiEnv.appId,
      appToken: ApiEnv.appToken,
      timeoutSeconds: ApiEnv.timeoutSeconds,
      authToken: token,
    ),
  );
});

/// API auth service for PIN login (API flavor only).
final apiAuthServiceProvider = Provider<ApiAuthService>((ref) => ApiAuthService(ref.read(apiClientProvider)));

/// Provides the [RoleService] implementation based on the current environment.
final roleServiceProvider = Provider<RoleService>((ref) {
  if (Environment.isDev) {
    return MockRoleService();
  } else if (Environment.isApi) {
    return ref.watch(apiRoleServiceProvider);
  } else {
    return FirebaseRoleService();
  }
});

/// Provides the [EmployeeStatusService] implementation based on the current environment.
final employeeStatusServiceProvider = Provider<EmployeeStatusService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeStatusService();
  } else if (Environment.isApi) {
    return ref.watch(apiEmployeeStatusServiceProvider);
  } else {
    return FirebaseEmployeeStatusService();
  }
});

/// Provides the [ShiftTypeService] implementation based on the current environment.
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) {
  if (Environment.isDev) {
    return MockShiftTypeService();
  } else if (Environment.isApi) {
    return ref.watch(apiShiftTypeServiceProvider);
  } else {
    return FirebaseShiftTypeService();
  }
});

/// Provides the [EmployeeService] implementation based on the current environment.
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else if (Environment.isApi) {
    return ref.watch(apiEmployeeServiceProvider);
  } else {
    final roleService = ref.watch(roleServiceProvider);
    final employeeStatusService = ref.watch(employeeStatusServiceProvider);
    return FirebaseEmployeeService(
      roleService: roleService,
      employeeStatusService: employeeStatusService,
    );
  }
});

/// Provides the [TimeRegistrationService] implementation based on the current environment.
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  } else if (Environment.isApi) {
    return ref.watch(apiTimeRegistrationServiceProvider);
  } else {
    return FirebaseTimeRegistrationService();
  }
});

/// Provides the [ShiftService] implementation based on the current environment.
final shiftServiceProvider = Provider<ShiftService>((ref) {
  if (Environment.isDev) {
    return MockShiftService();
  } else if (Environment.isApi) {
    return ref.watch(apiShiftServiceProvider);
  } else {
    return FirebaseShiftService();
  }
});

/// Provides the [ConfigService] implementation based on the current environment.
final configServiceProvider = Provider<ConfigService>((ref) {
  if (Environment.isDev) {
    return MockConfigService();
  } else if (Environment.isApi) {
    return ref.watch(apiConfigServiceProvider);
  } else {
    return FirebaseConfigService();
  }
});

/// Provides the application configuration.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});

/// Provides the list of all available shift types.
final shiftTypesProvider = FutureProvider<List<ShiftType>>((ref) async {
  final shiftTypeService = ref.watch(shiftTypeServiceProvider);
  return await shiftTypeService.getAllShiftTypes();
});

/// Provides the list of all available employee roles.
final rolesProvider = FutureProvider<List<Role>>((ref) async {
  final roleService = ref.watch(roleServiceProvider);
  return await roleService.getAllRoles();
});

/// Provides the list of all available employee statuses.
final employeeStatusesProvider = FutureProvider<List<EmployeeStatus>>((ref) async {
  final employeeStatusService = ref.watch(employeeStatusServiceProvider);
  return await employeeStatusService.getAllStatuses();
});

/// Provides the [EmployeeRepository] with its required service dependencies.
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
    shiftService: ref.watch(shiftServiceProvider),
  );
});

// API service providers (API flavor only)
final apiConfigServiceProvider = Provider<ConfigService>((ref) => ApiConfigService(ref.read(apiClientProvider)));
final apiEmployeeServiceProvider = Provider<EmployeeService>((ref) => ApiEmployeeService(ref.read(apiClientProvider)));
final apiShiftServiceProvider = Provider<ShiftService>((ref) => ApiShiftService(ref.read(apiClientProvider)));
final apiShiftTypeServiceProvider = Provider<ShiftTypeService>((ref) => ApiShiftTypeService(ref.read(apiClientProvider)));
final apiTimeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) => ApiTimeRegistrationService(ref.read(apiClientProvider)));
final apiRoleServiceProvider = Provider<RoleService>((ref) => ApiRoleService(ref.read(apiClientProvider)));
final apiEmployeeStatusServiceProvider = Provider<EmployeeStatusService>((ref) => ApiEmployeeStatusService(ref.read(apiClientProvider)));
