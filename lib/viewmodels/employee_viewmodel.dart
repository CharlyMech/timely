import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';

/// Estado de la lista de empleados
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

/// ViewModel para gestionar la lista de empleados
class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

  /// Carga todos los empleados con sus registros del día
  Future<void> loadEmployees() async {
    print('🔵 EmployeeViewModel: Iniciando loadEmployees()');
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 EmployeeViewModel: Llamando a repository.getEmployeesWithTodayRegistration()');
      final employees = await _repository.getEmployeesWithTodayRegistration();
      print('✅ EmployeeViewModel: Empleados obtenidos: ${employees.length}');
      state = state.copyWith(employees: employees, isLoading: false);
      print('✅ EmployeeViewModel: Estado actualizado correctamente');
    } catch (e, stackTrace) {
      print('❌ EmployeeViewModel: Error al cargar empleados: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar empleados: $e',
      );
    }
  }

  /// Refresca la lista de empleados (pull-to-refresh)
  Future<void> refreshEmployees() async {
    await loadEmployees();
  }

  /// Inicia la jornada de un empleado
  Future<void> startWorkday(String employeeId) async {
    try {
      final updatedEmployee = await _repository.startEmployeeWorkday(
        employeeId,
      );
      _updateEmployeeInList(updatedEmployee);
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar jornada: $e');
      rethrow;
    }
  }

  /// Finaliza la jornada de un empleado
  Future<void> endWorkday(String employeeId) async {
    try {
      final updatedEmployee = await _repository.endEmployeeWorkday(employeeId);
      _updateEmployeeInList(updatedEmployee);
    } catch (e) {
      state = state.copyWith(error: 'Error al finalizar jornada: $e');
      rethrow;
    }
  }

  /// Actualiza un empleado específico en la lista
  void _updateEmployeeInList(Employee updatedEmployee) {
    final updatedList = state.employees.map((e) {
      return e.id == updatedEmployee.id ? updatedEmployee : e;
    }).toList();

    state = state.copyWith(employees: updatedList);
  }

  /// Obtiene un empleado por ID
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

/// Provider del EmployeeViewModel
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(EmployeeViewModel.new);
