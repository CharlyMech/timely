import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/models/time_registration.dart';

class EmployeeProfileState {
  final Employee? employee;
  final List<Shift> upcomingShifts;
  final TimeRegistration? todayRegistration;
  final Shift? todayShift;
  final int monthlyShiftsCount;
  final int monthlyRegistrationsCount;
  final bool isLoading;
  final bool isLoadingShifts;
  final String? error;

  const EmployeeProfileState({
    this.employee,
    this.upcomingShifts = const [],
    this.todayRegistration,
    this.todayShift,
    this.monthlyShiftsCount = 0,
    this.monthlyRegistrationsCount = 0,
    this.isLoading = false,
    this.isLoadingShifts = false,
    this.error,
  });

  EmployeeProfileState copyWith({
    Employee? employee,
    List<Shift>? upcomingShifts,
    TimeRegistration? todayRegistration,
    Shift? todayShift,
    int? monthlyShiftsCount,
    int? monthlyRegistrationsCount,
    bool? isLoading,
    bool? isLoadingShifts,
    String? error,
    bool clearError = false,
    bool clearTodayRegistration = false,
    bool clearTodayShift = false,
  }) {
    return EmployeeProfileState(
      employee: employee ?? this.employee,
      upcomingShifts: upcomingShifts ?? this.upcomingShifts,
      todayRegistration: clearTodayRegistration
          ? null
          : (todayRegistration ?? this.todayRegistration),
      todayShift:
          clearTodayShift ? null : (todayShift ?? this.todayShift),
      monthlyShiftsCount: monthlyShiftsCount ?? this.monthlyShiftsCount,
      monthlyRegistrationsCount:
          monthlyRegistrationsCount ?? this.monthlyRegistrationsCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingShifts: isLoadingShifts ?? this.isLoadingShifts,
      error: clearError ? null : error,
    );
  }
}

class EmployeeProfileViewModel extends Notifier<EmployeeProfileState> {
  EmployeeProfileViewModel(this.employeeId);

  final String employeeId;

  @override
  EmployeeProfileState build() {
    return const EmployeeProfileState();
  }

  Future<void> loadEmployeeProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final employeeService = ref.read(employeeServiceProvider);
      final shiftService = ref.read(shiftServiceProvider);
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);

      // Load employee data
      final employee = await employeeService.getEmployeeById(employeeId);

      if (employee == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se encontró el empleado',
        );
        return;
      }

      // Load upcoming shifts
      final upcomingShifts = await shiftService.getUpcomingShifts(
        employeeId,
        limit: 10,
      );

      // Load today's shift
      final todayShift = await shiftService.getTodayShift(employeeId);

      // Load today's registration
      final todayRegistration =
          await timeRegistrationService.getTodayRegistration(employeeId);

      // Load monthly counts
      final now = DateTime.now();
      final monthlyShiftsCount = await shiftService.getMonthlyShiftsCount(
        employeeId,
        now,
      );

      // Count registrations for current month (we need to fetch them)
      final registrations = await timeRegistrationService.getEmployeeRegistrations(
        employeeId,
        limit: 100,
      );
      final monthlyRegistrationsCount = registrations.where((reg) {
        final regDate = reg.startTime;
        return regDate.year == now.year && regDate.month == now.month;
      }).length;

      state = state.copyWith(
        employee: employee,
        upcomingShifts: upcomingShifts,
        todayShift: todayShift,
        todayRegistration: todayRegistration,
        monthlyShiftsCount: monthlyShiftsCount,
        monthlyRegistrationsCount: monthlyRegistrationsCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el perfil: $e',
      );
    }
  }

  Future<void> refreshShifts() async {
    state = state.copyWith(isLoadingShifts: true);

    try {
      final shiftService = ref.read(shiftServiceProvider);

      // Load upcoming shifts
      final upcomingShifts = await shiftService.getUpcomingShifts(
        employeeId,
        limit: 10,
      );

      // Load today's shift
      final todayShift = await shiftService.getTodayShift(employeeId);

      // Load monthly count
      final now = DateTime.now();
      final monthlyShiftsCount = await shiftService.getMonthlyShiftsCount(
        employeeId,
        now,
      );

      state = state.copyWith(
        upcomingShifts: upcomingShifts,
        todayShift: todayShift,
        monthlyShiftsCount: monthlyShiftsCount,
        isLoadingShifts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingShifts: false,
        error: 'Error al actualizar los turnos: $e',
      );
    }
  }

  Future<void> refreshTodayData() async {
    try {
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);
      final shiftService = ref.read(shiftServiceProvider);

      final todayRegistration =
          await timeRegistrationService.getTodayRegistration(employeeId);
      final todayShift = await shiftService.getTodayShift(employeeId);

      state = state.copyWith(
        todayRegistration: todayRegistration,
        todayShift: todayShift,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al actualizar datos de hoy: $e',
      );
    }
  }
}

final employeeProfileViewModelProvider = NotifierProvider.family<
    EmployeeProfileViewModel,
    EmployeeProfileState,
    String>(EmployeeProfileViewModel.new);
