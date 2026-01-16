import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/repositories/employee_repository.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';
import 'package:timely/viewmodels/employee_registrations_viewmodel.dart';

/// State for employee detail screen including current employee and loading status.
class EmployeeDetailState {
  /// Currently loaded employee with registration and shift data.
  final Employee? employee;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Error message if loading or operations failed.
  final String? error;

  const EmployeeDetailState({
    this.employee,
    this.isLoading = false,
    this.error,
  });

  /// Creates a copy of this state with the given fields replaced.
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

/// ViewModel managing employee detail screen state and workday operations.
///
/// Handles loading employee data, starting/ending/pausing/resuming workdays,
/// and keeping state synchronized across multiple viewmodels.
class EmployeeDetailViewModel extends Notifier<EmployeeDetailState> {
  EmployeeDetailViewModel(this.employeeId);

  /// ID of the employee being managed.
  final String employeeId;
  late EmployeeRepository _repository;

  /// Loads employee data with current registration and today's shift.
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

  /// Refreshes employee data by reloading from repository.
  Future<void> refresh() async {
    await loadEmployee();
  }

  /// Starts a new workday for the employee.
  ///
  /// Creates a time registration and syncs state across viewmodels.
  /// Throws exception if no shift is assigned for today.
  Future<void> startWorkday() async {
    try {
      final updatedEmployee = await _repository.startEmployeeWorkday(
        employeeId,
      );
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

      // Update the registrations viewmodel to add the new registration to the history
      if (updatedEmployee.currentRegistration != null) {
        ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
            .updateRegistration(updatedEmployee.currentRegistration!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar jornada: $e');
      rethrow;
    }
  }

  /// Ends the current active workday.
  ///
  /// Records end time and syncs state across viewmodels.
  /// Throws exception if no active workday exists.
  Future<void> endWorkday() async {
    try {
      final updatedEmployee = await _repository.endEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

      // Update the registrations viewmodel to update the registration in the history
      if (updatedEmployee.currentRegistration != null) {
        ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
            .updateRegistration(updatedEmployee.currentRegistration!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al finalizar jornada: $e');
      rethrow;
    }
  }

  /// Pauses the current active workday.
  ///
  /// Records pause time and syncs state across viewmodels.
  /// Throws exception if no active workday or already paused.
  Future<void> pauseWorkday() async {
    try {
      if (state.employee?.currentRegistration == null) {
        throw Exception('No hay jornada activa para pausar');
      }

      final updatedEmployee = await _repository.pauseEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

      // Update the registrations viewmodel to update the registration in the history
      if (updatedEmployee.currentRegistration != null) {
        ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
            .updateRegistration(updatedEmployee.currentRegistration!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al pausar jornada: $e');
      rethrow;
    }
  }

  /// Resumes a paused workday.
  ///
  /// Records resume time and syncs state across viewmodels.
  /// Throws exception if no active workday or not paused.
  Future<void> resumeWorkday() async {
    try {
      if (state.employee?.currentRegistration == null) {
        throw Exception('No hay jornada activa para reanudar');
      }

      final updatedEmployee = await _repository.resumeEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee);

      // Update the main employee list to keep it in sync
      ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

      // Update the registrations viewmodel to update the registration in the history
      if (updatedEmployee.currentRegistration != null) {
        ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
            .updateRegistration(updatedEmployee.currentRegistration!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al reanudar jornada: $e');
      rethrow;
    }
  }

  @override
  EmployeeDetailState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeDetailState();
  }
}

/// Provider for employee detail viewmodel, parameterized by employee ID.
final employeeDetailViewModelProvider =
    NotifierProvider.family<
      EmployeeDetailViewModel,
      EmployeeDetailState,
      String
    >(EmployeeDetailViewModel.new);
