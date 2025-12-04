import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';

/// Estado del detalle de un empleado
class EmployeeDetailState {
  final Employee? employee;
  final bool isLoading;
  final String? error;

  const EmployeeDetailState({
    this.employee,
    this.isLoading = false,
    this.error,
  });

  EmployeeDetailState copyWith({
    Employee? employee,
    bool? isLoading,
    String? error,
  }) {
    return EmployeeDetailState(
      employee: employee ?? this.employee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel para el detalle de un empleado específico
class EmployeeDetailViewModel extends Notifier<EmployeeDetailState> {
  EmployeeDetailViewModel(this.employeeId);

  final String employeeId;
  late EmployeeRepository _repository;

  /// Carga los datos del empleado
  Future<void> loadEmployee() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final employee = await _repository.getEmployeeWithRegistration(employeeId);
      state = state.copyWith(employee: employee, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar empleado: $e',
      );
    }
  }

  /// Refresca los datos del empleado
  Future<void> refresh() async {
    await loadEmployee();
  }

  /// Inicia la jornada
  Future<void> startWorkday() async {
    try {
      final updatedEmployee = await _repository.startEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar jornada: $e');
      rethrow;
    }
  }

  /// Finaliza la jornada
  Future<void> endWorkday() async {
    try {
      final updatedEmployee = await _repository.endEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);
    } catch (e) {
      state = state.copyWith(error: 'Error al finalizar jornada: $e');
      rethrow;
    }
  }

  @override
  EmployeeDetailState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeDetailState();
  }
}

/// Provider del EmployeeDetailViewModel
/// Nota: usamos .family para crear un provider por cada employeeId
final employeeDetailViewModelProvider = NotifierProvider.family<
    EmployeeDetailViewModel, EmployeeDetailState, String>(
  EmployeeDetailViewModel.new,
);