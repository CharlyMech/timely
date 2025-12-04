import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';

class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

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

class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

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

  Future<void> refreshEmployees() async {
    await loadEmployees();
  }

  void updateEmployee(Employee updatedEmployee) {
    print('[EmployeeViewModel] updateEmployee called for: ${updatedEmployee.id}');
    print('[EmployeeViewModel] Current registration: ${updatedEmployee.currentRegistration?.id}');
    print('[EmployeeViewModel] Is active: ${updatedEmployee.currentRegistration?.isActive}');

    _updateEmployeeInList(updatedEmployee);

    print('[EmployeeViewModel] State updated. Total employees: ${state.employees.length}');
  }

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

final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(EmployeeViewModel.new);
