import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:timely/services/config_service.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/employee_status_service.dart';
import 'package:timely/services/role_service.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/services/shift_type_service.dart';
import 'package:timely/services/time_registration_service.dart';

/// Contract for the app's data layer: one implementation per mode (dev/api).
///
/// [Environment.dataSourcesProvider] returns the implementation for the current
/// [Environment.flavor]. Use this instead of branching on [Environment.isDev]
/// or [Environment.isApi] when resolving services.
abstract class AppDataSources {
  ConfigService configService(Ref ref);
  EmployeeService employeeService(Ref ref);
  EmployeeStatusService employeeStatusService(Ref ref);
  RoleService roleService(Ref ref);
  ShiftService shiftService(Ref ref);
  ShiftTypeService shiftTypeService(Ref ref);
  TimeRegistrationService timeRegistrationService(Ref ref);
}

/// Manages application environment configuration and build flavors.
///
/// Provides access to the current environment flavor (dev/api) and
/// utility methods to check which environment the app is running in.
///
/// Data sources: dev → mock, api → REST API.
/// To build with a specific flavor:
/// ```bash
/// flutter run --dart-define=FLAVOR=dev
/// flutter run --dart-define=FLAVOR=api --dart-define=API_URL=http://localhost:3000
/// ```
class Environment {
  /// The compile-time constant key used to read the environment flavor.
  static const String _flavorKey = 'FLAVOR';

  /// The compile-time constant key used to read the API URL.
  static const String _apiUrlKey = 'API_URL';

  /// Returns the current environment flavor.
  ///
  /// Defaults to 'dev' if no flavor is specified at compile time.
  static String get flavor {
    return const String.fromEnvironment(_flavorKey, defaultValue: 'dev');
  }

  /// Returns the API URL for API mode.
  ///
  /// Returns an empty string if not specified at compile time.
  /// Should only be used when [isApi] is true.
  static String get apiUrl {
    return const String.fromEnvironment(_apiUrlKey, defaultValue: '');
  }

  /// Returns `true` if the app is running in development mode (mock).
  static bool get isDev => flavor == 'dev';

  /// Returns `true` if the app is running in API mode (REST API).
  static bool get isApi => flavor == 'api';

  /// Returns `true` if the API URL is configured.
  static bool get hasApiUrl => apiUrl.isNotEmpty;

  /// Current data source mode: `dev` (mock) or `api`.
  static String get dataMode => flavor;
}
