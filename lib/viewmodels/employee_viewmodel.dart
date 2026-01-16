import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';

/// State for the main employee list with current registrations.
class EmployeeState {
  /// List of all employees with their current registration and today's shift.
  final List<Employee> employees;

  /// Whether employee data is currently being loaded.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  /// Creates a copy of this state with the given fields replaced.
  EmployeeState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel managing the main employee list for the staff screen.
///
/// Loads all employees with their current time registrations and today's shifts.
/// Provides methods for updating individual employees when their data changes.
class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

  /// Loads all employees with current registration and today's shift.
  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final employees = await _repository.getEmployeesWithTodayRegistration();
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e, stackTrace) {
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar empleados: $e',
      );
    }
  }

  /// Refreshes the employee list by reloading from repository.
  Future<void> refreshEmployees() async {
    await loadEmployees();
  }

  /// Updates a single employee in the list.
  ///
  /// Called when an employee's data changes (e.g., time registration updated)
  /// to keep the list synchronized without full reload.
  void updateEmployee(Employee updatedEmployee) {
    print('[EmployeeViewModel] updateEmployee called for: ${updatedEmployee.id}');
    print('[EmployeeViewModel] Current registration: ${updatedEmployee.currentRegistration?.id}');
    print('[EmployeeViewModel] Is active: ${updatedEmployee.currentRegistration?.isActive}');

    _updateEmployeeInList(updatedEmployee);

    print('[EmployeeViewModel] State updated. Total employees: ${state.employees.length}');
  }

  /// Internal method to update employee in the state list.
  void _updateEmployeeInList(Employee updatedEmployee) {
    final updatedList = state.employees.map((e) {
      if (e.id == updatedEmployee.id) {
        print('[EmployeeViewModel] Updating employee ${e.id} in list');
        return updatedEmployee;
      }
      return e;
    }).toList();

    state = state.copyWith(employees: updatedList);
  }

  /// Finds an employee by ID from the current list.
  ///
  /// Returns null if not found.
  Employee? getEmployeeById(String id) {
    try {
      return state.employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  EmployeeState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeState();
  }
}

/// Provider for the main employee list viewmodel.
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(EmployeeViewModel.new);
