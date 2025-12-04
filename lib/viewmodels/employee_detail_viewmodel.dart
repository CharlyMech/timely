import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';

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

class EmployeeDetailViewModel extends Notifier<EmployeeDetailState> {
  EmployeeDetailViewModel(this.employeeId);

  final String employeeId;
  late EmployeeRepository _repository;

  Future<void> loadEmployee() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final employee = await _repository.getEmployeeWithRegistration(
        employeeId,
      );
      state = state.copyWith(employee: employee, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar empleado: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadEmployee();
  }

  Future<void> startWorkday() async {
    try {
      final updatedEmployee = await _repository.startEmployeeWorkday(
        employeeId,
      );
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar jornada: $e');
      rethrow;
    }
  }

  Future<void> endWorkday() async {
    try {
      final updatedEmployee = await _repository.endEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);
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

final employeeDetailViewModelProvider =
    NotifierProvider.family<
      EmployeeDetailViewModel,
      EmployeeDetailState,
      String
    >(EmployeeDetailViewModel.new);
