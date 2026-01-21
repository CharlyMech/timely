import 'package:timely/models/employee.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/services/employee_service.dart';
import 'package:timely/services/shift_service.dart';
import 'package:timely/services/time_registration_service.dart';

/// Repository that orchestrates employee-related services and operations.
///
/// Acts as a facade over [EmployeeService], [TimeRegistrationService], and
/// [ShiftService], coordinating data retrieval and updates across multiple
/// services to provide complete employee information.
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

  /// Retrieves all employees with their current time registration and today's shift.
  ///
  /// Fetches employees and enriches each with:
  /// - Current time registration (if active today)
  /// - Today's assigned shift (if any)
  ///
  /// Uses batch queries to load all registrations and shifts in parallel,
  /// avoiding N+1 query problems for better performance.
  ///
  /// Returns a list of fully populated [Employee] objects.
  Future<List<Employee>> getEmployeesWithTodayRegistration() async {
    // Execute all queries in parallel for optimal performance
    final results = await Future.wait([
      _employeeService.getEmployees(),
      _timeRegistrationService.getAllTodayRegistrations(),
      _shiftService.getAllTodayShifts(),
    ]);

    final employees = results[0] as List<Employee>;
    final registrationsByEmployee = results[1] as Map<String, TimeRegistration>;
    final shiftsByEmployee = results[2] as Map<String, Shift>;

    // Enrich each employee with their registration and shift from the maps
    return employees.map((employee) {
      return employee.copyWith(
        currentRegistration: registrationsByEmployee[employee.id],
        todayShift: shiftsByEmployee[employee.id],
      );
    }).toList();
  }

  /// Retrieves a single employee with their current registration and today's shift.
  ///
  /// Returns null if the employee is not found.
  Future<Employee?> getEmployeeWithRegistration(String employeeId) async {
    final employee = await _employeeService.getEmployeeById(employeeId);
    if (employee == null) return null;

    final registration = await _timeRegistrationService.getTodayRegistration(
      employeeId,
    );
    final todayShift = await _shiftService.getTodayShift(employeeId);
    return employee.copyWith(
      currentRegistration: registration,
      todayShift: todayShift,
    );
  }

  /// Starts a workday for the specified employee.
  ///
  /// Validates that the employee has a shift assigned for today, then creates
  /// a new time registration with the current timestamp as start time.
  ///
  /// Returns the updated [Employee] with the new registration.
  ///
  /// Throws:
  /// - [Exception] if no shift is assigned for today
  /// - [Exception] if employee is not found
  Future<Employee> startEmployeeWorkday(String employeeId) async {
    final todayShift = await _shiftService.getTodayShift(employeeId);

    if (todayShift == null) {
      throw Exception('No tienes un turno asignado para hoy');
    }

    final registration = await _timeRegistrationService.startWorkday(
      employeeId,
      todayShift.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);

    if (employee == null) {
      throw Exception('Empleado no encontrado');
    }

    return employee.copyWith(
      currentRegistration: registration,
      todayShift: todayShift,
    );
  }

  /// Ends the current workday for the specified employee.
  ///
  /// Records the current timestamp as the end time for the active registration.
  ///
  /// Returns the updated [Employee] with the completed registration.
  ///
  /// Throws:
  /// - [Exception] if no active workday exists
  /// - [Exception] if employee is not found
  Future<Employee> endEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No hay una jornada activa');
    }

    final updatedRegistration = await _timeRegistrationService.endWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);
    final todayShift = await _shiftService.getTodayShift(employeeId);

    if (employee == null) {
      throw Exception('Empleado no encontrado');
    }

    return employee.copyWith(
      currentRegistration: updatedRegistration,
      todayShift: todayShift,
    );
  }

  /// Pauses the current active workday for the specified employee.
  ///
  /// Records the current timestamp as the pause time.
  ///
  /// Returns the updated [Employee] with the paused registration.
  ///
  /// Throws:
  /// - [Exception] if no active workday exists
  /// - [Exception] if workday is already paused
  /// - [Exception] if employee is not found
  Future<Employee> pauseEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No hay una jornada activa');
    }

    if (currentRegistration.isPaused) {
      throw Exception('La jornada ya está pausada');
    }

    final updatedRegistration = await _timeRegistrationService.pauseWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);
    final todayShift = await _shiftService.getTodayShift(employeeId);

    if (employee == null) {
      throw Exception('Empleado no encontrado');
    }

    return employee.copyWith(
      currentRegistration: updatedRegistration,
      todayShift: todayShift,
    );
  }

  /// Resumes a paused workday for the specified employee.
  ///
  /// Records the current timestamp as the resume time.
  ///
  /// Returns the updated [Employee] with the resumed registration.
  ///
  /// Throws:
  /// - [Exception] if no active workday exists
  /// - [Exception] if workday is not currently paused
  /// - [Exception] if employee is not found
  Future<Employee> resumeEmployeeWorkday(String employeeId) async {
    final currentRegistration = await _timeRegistrationService
        .getTodayRegistration(employeeId);

    if (currentRegistration == null || !currentRegistration.isActive) {
      throw Exception('No hay una jornada activa');
    }

    if (!currentRegistration.isPaused) {
      throw Exception('La jornada no está pausada');
    }

    final updatedRegistration = await _timeRegistrationService.resumeWorkday(
      currentRegistration.id,
    );
    final employee = await _employeeService.getEmployeeById(employeeId);
    final todayShift = await _shiftService.getTodayShift(employeeId);

    if (employee == null) {
      throw Exception('Empleado no encontrado');
    }

    return employee.copyWith(
      currentRegistration: updatedRegistration,
      todayShift: todayShift,
    );
  }
}
