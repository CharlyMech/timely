import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/models/time_registration.dart';

class EmployeeProfileState {
  final Employee? employee;
  final List<Shift> calendarShifts;
  final TimeRegistration? todayRegistration;
  final Shift? todayShift;
  final int monthlyShiftsCount;
  final int monthlyRegistrationsCount;
  final bool isLoading;
  final bool isLoadingShifts;
  final String? error;

  const EmployeeProfileState({
    this.employee,
    this.calendarShifts = const [],
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
    List<Shift>? calendarShifts,
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
      calendarShifts: calendarShifts ?? this.calendarShifts,
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
        todayShift: todayShift,
        todayRegistration: todayRegistration,
        monthlyShiftsCount: monthlyShiftsCount,
        monthlyRegistrationsCount: monthlyRegistrationsCount,
        isLoading: false,
      );

      // Load initial calendar shifts for the current month
      await loadCalendarShifts(now);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el perfil: $e',
      );
    }
  }

  Future<void> loadCalendarShifts(DateTime focusedDate) async {
    state = state.copyWith(isLoadingShifts: true);

    try {
      final shiftService = ref.read(shiftServiceProvider);

      // Calculate range: from 2 months before to 2 months after the focused date
      final startDate = DateTime(
        focusedDate.year,
        focusedDate.month - 2,
        1,
      );
      final endDate = DateTime(
        focusedDate.year,
        focusedDate.month + 3,
        0,
      );

      // Load shifts in the date range
      final calendarShifts = await shiftService.getEmployeeShifts(
        employeeId,
        startDate: startDate,
        endDate: endDate,
        limit: 200,
      );

      state = state.copyWith(
        calendarShifts: calendarShifts,
        isLoadingShifts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingShifts: false,
        error: 'Error al cargar los turnos del calendario: $e',
      );
    }
  }

  Future<void> refreshShifts(DateTime focusedDate) async {
    await loadCalendarShifts(focusedDate);

    try {
      final shiftService = ref.read(shiftServiceProvider);

      // Load today's shift
      final todayShift = await shiftService.getTodayShift(employeeId);

      // Load monthly count
      final now = DateTime.now();
      final monthlyShiftsCount = await shiftService.getMonthlyShiftsCount(
        employeeId,
        now,
      );

      state = state.copyWith(
        todayShift: todayShift,
        monthlyShiftsCount: monthlyShiftsCount,
      );
    } catch (e) {
      state = state.copyWith(
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
