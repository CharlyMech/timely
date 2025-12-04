import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/time_registration_service.dart';

// Employee repository that orchestrates services
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeRegistrationService;

  EmployeeRepository({
    required EmployeeService employeeService,
    required TimeRegistrationService timeRegistrationService,
  }) : _employeeService = employeeService,
       _timeRegistrationService = timeRegistrationService;

  Future<List<Employee>> getEmployeesWithTodayRegistration() async {
    final employees = await _employeeService.getEmployees();

    final employeesWithRegistration = await Future.wait(
      employees.map((employee) async {
        final registration = await _timeRegistrationService
            .getTodayRegistration(employee.id);
        return employee.copyWith(currentRegistration: registration);
      }),
    );

    return employeesWithRegistration;
  }

  Future<Employee?> getEmployeeWithRegistration(String employeeId) async {
    final employee = await _employeeService.getEmployeeById(employeeId);
    if (employee == null) return null;

    final registration = await _timeRegistrationService.getTodayRegistration(
      employeeId,
    );
    return employee.copyWith(currentRegistration: registration);
  }

  Future<Employee> startEmployeeWorkday(String employeeId) async {
    final registration = await _timeRegistrationService.startWorkday(
      employeeId,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);

    if (employee == null) {
      throw Exception('Employee not found');
    }

    return employee.copyWith(currentRegistration: registration);
  }

  Future<Employee> endEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No active workday found');
    }

    final updatedRegistration = await _timeRegistrationService.endWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);

    if (employee == null) {
      throw Exception('Employee not found');
    }

    return employee.copyWith(currentRegistration: updatedRegistration);
  }
}
