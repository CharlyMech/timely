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

    try {
      // Cargar registros del mes actual
      await loadMonthRegistrations(targetMonth);

      state = state.copyWith(
        isLoading: false,
        currentMonth: targetMonth,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los registros: $e',
      );
    }
  }

  Future<void> loadMonthRegistrations(DateTime month) async {
    // Clave para identificar el mes (formato: YYYY-MM)
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Si ya cargamos este mes, solo actualizamos el contador y salimos
    if (state.loadedMonths.contains(monthKey)) {
      // Eliminar duplicados si existen (por si acaso)
      final uniqueRegistrations = <String, TimeRegistration>{};
      for (var reg in state.registrations) {
        uniqueRegistrations[reg.id] = reg;
      }
      final cleanedRegistrations = uniqueRegistrations.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      final monthlyCount = cleanedRegistrations.where((reg) {
        final regDate = reg.startTime;
        return regDate.year == month.year && regDate.month == month.month;
      }).length;

      state = state.copyWith(
        currentMonth: month,
        monthlyCount: monthlyCount,
        registrations: cleanedRegistrations,
      );
      return;
    }

    state = state.copyWith(isLoadingMonth: true);

    try {
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);

      // Cargar registros del mes específico
      final monthRegistrations = await timeRegistrationService.getMonthlyRegistrations(
        employeeId,
        month,
      );

      // Combinar con registros ya cargados de otros meses, EVITANDO DUPLICADOS
      final allRegistrations = [...state.registrations];

      for (var newReg in monthRegistrations) {
        // Solo añadir si no existe ya (por ID)
        final exists = allRegistrations.any((r) => r.id == newReg.id);
        if (!exists) {
          allRegistrations.add(newReg);
        }
      }

      // Ordenar por fecha descendente (más reciente primero)
      allRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Marcar este mes como cargado
      final updatedLoadedMonths = {...state.loadedMonths, monthKey};

      final monthlyCount = monthRegistrations.length;

      state = state.copyWith(
        registrations: allRegistrations,
        loadedMonths: updatedLoadedMonths,
        currentMonth: month,
        monthlyCount: monthlyCount,
        isLoadingMonth: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMonth: false,
        error: 'Error al cargar registros del mes: $e',
      );
    }
  }

  /// Añade o actualiza un registro en el estado local
  /// Se llama cuando se crea o actualiza un registro para mantener el estado sincronizado
  void updateRegistration(TimeRegistration registration) {
    // Buscar si ya existe el registro
    final existingIndex = state.registrations.indexWhere((r) => r.id == registration.id);

    List<TimeRegistration> updatedRegistrations;
    if (existingIndex >= 0) {
      // Actualizar registro existente
      updatedRegistrations = [...state.registrations];
      updatedRegistrations[existingIndex] = registration;
    } else {
      // Añadir nuevo registro
      updatedRegistrations = [...state.registrations, registration];
    }

    // Ordenar por fecha descendente (más reciente primero)
    updatedRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Actualizar el contador del mes actual si es necesario
    final currentMonth = state.currentMonth ?? DateTime.now();
    final monthlyCount = updatedRegistrations.where((reg) {
      final regDate = reg.startTime;
      return regDate.year == currentMonth.year && regDate.month == currentMonth.month;
    }).length;

    state = state.copyWith(
      registrations: updatedRegistrations,
      monthlyCount: monthlyCount,
    );
  }
}

final employeeRegistrationsViewModelProvider = NotifierProvider.family<
    EmployeeRegistrationsViewModel,
    EmployeeRegistrationsState,
    String>(EmployeeRegistrationsViewModel.new);
