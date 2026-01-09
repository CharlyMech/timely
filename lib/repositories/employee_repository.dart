import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/services/time_registration_service.dart';

// Employee repository that orchestrates services
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeRegistrationService;
  final ShiftService _shiftService;

  EmployeeRepository({
    required EmployeeService employeeService,
    required TimeRegistrationService timeRegistrationService,
    required ShiftService shiftService,
  }) : _employeeService = employeeService,
       _timeRegistrationService = timeRegistrationService,
       _shiftService = shiftService;

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
    final todayShift = await _shiftService.getTodayShift(employeeId);

    if (todayShift == null) {
      throw Exception('No shift scheduled for today');
    }

    final registration = await _timeRegistrationService.startWorkday(
      employeeId,
      todayShift.id,
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

  Future<Employee> pauseEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No active workday found');
    }

    if (currentRegistration.isPaused) {
      throw Exception('Workday is already paused');
    }

    final updatedRegistration = await _timeRegistrationService.pauseWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);

    if (employee == null) {
      throw Exception('Employee not found');
    }

    return employee.copyWith(currentRegistration: updatedRegistration);
  }

  Future<Employee> resumeEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No active workday found');
    }

    if (!currentRegistration.isPaused) {
      throw Exception('Workday is not paused');
    }

    final updatedRegistration = await _timeRegistrationService.resumeWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);

    if (employee == null) {
      throw Exception('Employee not found');
    }

    return employee.copyWith(currentRegistration: updatedRegistration);
  }
}
