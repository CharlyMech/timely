import 'package:flutter/foundation.dart';
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
import 'package:timely/config/env.dart';
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

/// Provides the API client for API flavor.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ApiConfig(
      baseUrl: Env.baseUrl,
      appId: Env.appId,
      appToken: Env.appToken,
      timeoutSeconds: Env.timeoutSeconds,
    ),
  );
});

/// API auth service for PIN login (API flavor only).
final apiAuthServiceProvider = Provider<ApiAuthService>((ref) => ApiAuthService(ref.read(apiClientProvider)));

// API service providers (used by ApiDataSources)
final apiConfigServiceProvider = Provider<ConfigService>((ref) => ApiConfigService(ref.read(apiClientProvider)));
final apiEmployeeServiceProvider = Provider<EmployeeService>((ref) => ApiEmployeeService(ref.read(apiClientProvider)));
final apiShiftServiceProvider = Provider<ShiftService>((ref) => ApiShiftService(ref.read(apiClientProvider)));
final apiShiftTypeServiceProvider = Provider<ShiftTypeService>((ref) => ApiShiftTypeService(ref.read(apiClientProvider)));
final apiTimeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) => ApiTimeRegistrationService(ref.read(apiClientProvider)));
final apiRoleServiceProvider = Provider<RoleService>((ref) => ApiRoleService(ref.read(apiClientProvider)));
final apiEmployeeStatusServiceProvider = Provider<EmployeeStatusService>((ref) => ApiEmployeeStatusService(ref.read(apiClientProvider)));

/// Data source implementation for the current [Environment.flavor].
final dataSourcesProvider = Provider<AppDataSources>((ref) {
  if (Environment.isDev) {
    debugPrint('[Providers] Using MockDataSources (FLAVOR=dev)');
    return _MockDataSources();
  }
  debugPrint('[Providers] Using ApiDataSources (FLAVOR=api)');
  return _ApiDataSources();
});

/// Provides [ConfigService] from the current data source.
final configServiceProvider = Provider<ConfigService>((ref) => ref.watch(dataSourcesProvider).configService(ref));

/// Provides [RoleService] from the current data source.
final roleServiceProvider = Provider<RoleService>((ref) => ref.watch(dataSourcesProvider).roleService(ref));

/// Provides [EmployeeStatusService] from the current data source.
final employeeStatusServiceProvider = Provider<EmployeeStatusService>((ref) => ref.watch(dataSourcesProvider).employeeStatusService(ref));

/// Provides [ShiftTypeService] from the current data source.
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) => ref.watch(dataSourcesProvider).shiftTypeService(ref));

/// Provides [EmployeeService] from the current data source.
final employeeServiceProvider = Provider<EmployeeService>((ref) => ref.watch(dataSourcesProvider).employeeService(ref));

/// Provides [TimeRegistrationService] from the current data source.
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) => ref.watch(dataSourcesProvider).timeRegistrationService(ref));

/// Provides [ShiftService] from the current data source.
final shiftServiceProvider = Provider<ShiftService>((ref) => ref.watch(dataSourcesProvider).shiftService(ref));

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

// --- AppDataSources implementations (one per Environment.flavor) ---

class _MockDataSources implements AppDataSources {
  @override
  ConfigService configService(Ref ref) => MockConfigService();

  @override
  EmployeeService employeeService(Ref ref) => MockEmployeeService();

  @override
  EmployeeStatusService employeeStatusService(Ref ref) => MockEmployeeStatusService();

  @override
  RoleService roleService(Ref ref) => MockRoleService();

  @override
  ShiftService shiftService(Ref ref) => MockShiftService();

  @override
  ShiftTypeService shiftTypeService(Ref ref) => MockShiftTypeService();

  @override
  TimeRegistrationService timeRegistrationService(Ref ref) => MockTimeRegistrationService();
}

class _ApiDataSources implements AppDataSources {
  @override
  ConfigService configService(Ref ref) => ref.read(apiConfigServiceProvider);

  @override
  EmployeeService employeeService(Ref ref) => ref.read(apiEmployeeServiceProvider);

  @override
  EmployeeStatusService employeeStatusService(Ref ref) => ref.read(apiEmployeeStatusServiceProvider);

  @override
  RoleService roleService(Ref ref) => ref.read(apiRoleServiceProvider);

  @override
  ShiftService shiftService(Ref ref) => ref.read(apiShiftServiceProvider);

  @override
  ShiftTypeService shiftTypeService(Ref ref) => ref.read(apiShiftTypeServiceProvider);

  @override
  TimeRegistrationService timeRegistrationService(Ref ref) => ref.read(apiTimeRegistrationServiceProvider);
}
