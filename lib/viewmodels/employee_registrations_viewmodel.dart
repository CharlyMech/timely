import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/time_registration.dart';

class EmployeeRegistrationsState {
  final List<TimeRegistration> registrations;
  final bool isLoading;
  final bool isLoadingMonth;
  final String? error;
  final int totalCount;
  final int monthlyCount;
  final DateTime? currentMonth;
  final Set<String> loadedMonths; // Para trackear qué meses ya se cargaron

  const EmployeeRegistrationsState({
    this.registrations = const [],
    this.isLoading = false,
    this.isLoadingMonth = false,
    this.error,
    this.totalCount = 0,
    this.monthlyCount = 0,
    this.currentMonth,
    this.loadedMonths = const {},
  });

  EmployeeRegistrationsState copyWith({
    List<TimeRegistration>? registrations,
    bool? isLoading,
    bool? isLoadingMonth,
    String? error,
    int? totalCount,
    int? monthlyCount,
    DateTime? currentMonth,
    Set<String>? loadedMonths,
  }) {
    return EmployeeRegistrationsState(
      registrations: registrations ?? this.registrations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMonth: isLoadingMonth ?? this.isLoadingMonth,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      monthlyCount: monthlyCount ?? this.monthlyCount,
      currentMonth: currentMonth ?? this.currentMonth,
      loadedMonths: loadedMonths ?? this.loadedMonths,
    );
  }

  int getMonthlyCount(DateTime month) {
    return registrations.where((reg) {
      final regDate = reg.startTime;
      return regDate.year == month.year && regDate.month == month.month;
    }).length;
  }
}

class EmployeeRegistrationsViewModel extends Notifier<EmployeeRegistrationsState> {
  EmployeeRegistrationsViewModel(this.employeeId);

  final String employeeId;

  @override
  EmployeeRegistrationsState build() {
    return const EmployeeRegistrationsState();
  }

  Future<void> loadInitialRegistrations({DateTime? month}) async {
    state = state.copyWith(isLoading: true, error: null);
    final targetMonth = month ?? DateTime.now();

    print('[EmployeeRegistrationsVM] loadInitialRegistrations - Mes: ${targetMonth.year}-${targetMonth.month}');

    try {
      // Cargar registros del mes actual
      await loadMonthRegistrations(targetMonth);

      print('[EmployeeRegistrationsVM] Carga inicial completada. Registros en memoria: ${state.registrations.length}');

      state = state.copyWith(
        isLoading: false,
        currentMonth: targetMonth,
      );
    } catch (e) {
      print('[EmployeeRegistrationsVM] ERROR en carga inicial: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los registros: $e',
      );
    }
  }

  Future<void> loadMonthRegistrations(DateTime month) async {
    // Clave para identificar el mes (formato: YYYY-MM)
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    print('[EmployeeRegistrationsVM] loadMonthRegistrations - Mes solicitado: $monthKey');
    print('[EmployeeRegistrationsVM] Meses ya cargados: ${state.loadedMonths}');

    // Si ya cargamos este mes, solo actualizamos el contador y salimos
    if (state.loadedMonths.contains(monthKey)) {
      print('[EmployeeRegistrationsVM] Mes $monthKey ya estaba cargado, usando caché');

      final monthlyCount = state.registrations.where((reg) {
        final regDate = reg.startTime;
        return regDate.year == month.year && regDate.month == month.month;
      }).length;

      state = state.copyWith(
        currentMonth: month,
        monthlyCount: monthlyCount,
      );
      return;
    }

    print('[EmployeeRegistrationsVM] Cargando registros del mes $monthKey...');
    state = state.copyWith(isLoadingMonth: true);

    try {
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);

      // Cargar registros del mes específico
      final monthRegistrations = await timeRegistrationService.getMonthlyRegistrations(
        employeeId,
        month,
      );

      print('[EmployeeRegistrationsVM] Registros cargados para $monthKey: ${monthRegistrations.length}');

      // Combinar con registros ya cargados de otros meses
      final allRegistrations = [...state.registrations, ...monthRegistrations];

      // Ordenar por fecha descendente (más reciente primero)
      allRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Marcar este mes como cargado
      final updatedLoadedMonths = {...state.loadedMonths, monthKey};

      final monthlyCount = monthRegistrations.length;

      print('[EmployeeRegistrationsVM] Total registros en memoria: ${allRegistrations.length}');
      print('[EmployeeRegistrationsVM] Registros del mes $monthKey: $monthlyCount');
      print('[EmployeeRegistrationsVM] Meses cargados ahora: $updatedLoadedMonths');

      state = state.copyWith(
        registrations: allRegistrations,
        loadedMonths: updatedLoadedMonths,
        currentMonth: month,
        monthlyCount: monthlyCount,
        isLoadingMonth: false,
      );
    } catch (e) {
      print('[EmployeeRegistrationsVM] ERROR al cargar registros: $e');
      state = state.copyWith(
        isLoadingMonth: false,
        error: 'Error al cargar registros del mes: $e',
      );
    }
  }
}

final employeeRegistrationsViewModelProvider = NotifierProvider.family<
    EmployeeRegistrationsViewModel,
    EmployeeRegistrationsState,
    String>(EmployeeRegistrationsViewModel.new);
