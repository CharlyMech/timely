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
  final Set<String> loadedMonths; // Para trackear qué meses ya se cargaron

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
    this.loadedMonths = const {},
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
    Set<String>? loadedMonths,
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
      loadedMonths: loadedMonths ?? this.loadedMonths,
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

      // Load monthly counts for current month
      final now = DateTime.now();
      final monthlyShiftsCount = await shiftService.getMonthlyShiftsCount(
        employeeId,
        now,
      );

      // Usar el nuevo método optimizado para contar registros del mes actual
      final monthlyRegistrationsCount =
          await timeRegistrationService.getMonthlyRegistrationsCount(
            employeeId,
            now,
          );

      state = state.copyWith(
        employee: employee,
        todayShift: todayShift,
        todayRegistration: todayRegistration,
        monthlyShiftsCount: monthlyShiftsCount,
        monthlyRegistrationsCount: monthlyRegistrationsCount,
        isLoading: false,
      );

      // Load initial calendar shifts for the current month only
      await loadCalendarShifts(now);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el perfil: $e',
      );
    }
  }

  Future<void> loadCalendarShifts(DateTime focusedDate) async {
    // Clave para identificar el mes (formato: YYYY-MM)
    final monthKey = '${focusedDate.year}-${focusedDate.month.toString().padLeft(2, '0')}';

    print('[EmployeeProfileVM] loadCalendarShifts - Mes solicitado: $monthKey');
    print('[EmployeeProfileVM] Meses ya cargados: ${state.loadedMonths}');

    // Si ya cargamos este mes, no volver a cargarlo
    if (state.loadedMonths.contains(monthKey)) {
      print('[EmployeeProfileVM] Mes $monthKey ya estaba cargado, usando caché');
      return;
    }

    print('[EmployeeProfileVM] Cargando turnos del mes $monthKey...');
    state = state.copyWith(isLoadingShifts: true);

    try {
      final shiftService = ref.read(shiftServiceProvider);

      // Cargar solo los turnos del mes enfocado
      final monthShifts = await shiftService.getMonthlyShifts(
        employeeId,
        focusedDate,
      );

      print('[EmployeeProfileVM] Turnos cargados para $monthKey: ${monthShifts.length}');

      // Combinar con los turnos ya cargados de otros meses
      final allShifts = [...state.calendarShifts, ...monthShifts];

      // Marcar este mes como cargado
      final updatedLoadedMonths = {...state.loadedMonths, monthKey};

      print('[EmployeeProfileVM] Total de turnos en memoria: ${allShifts.length}');
      print('[EmployeeProfileVM] Meses cargados ahora: $updatedLoadedMonths');

      state = state.copyWith(
        calendarShifts: allShifts,
        loadedMonths: updatedLoadedMonths,
        isLoadingShifts: false,
      );
    } catch (e) {
      print('[EmployeeProfileVM] ERROR al cargar turnos: $e');
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
