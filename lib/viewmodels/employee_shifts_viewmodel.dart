import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/shift.dart';

class EmployeeShiftsState {
  final List<Shift> shifts;
  final bool isLoading;
  final bool isLoadingMonth;
  final String? error;
  final Set<String> loadedMonths; // Para trackear qué meses ya se cargaron

  const EmployeeShiftsState({
    this.shifts = const [],
    this.isLoading = false,
    this.isLoadingMonth = false,
    this.error,
    this.loadedMonths = const {},
  });

  EmployeeShiftsState copyWith({
    List<Shift>? shifts,
    bool? isLoading,
    bool? isLoadingMonth,
    String? error,
    Set<String>? loadedMonths,
  }) {
    return EmployeeShiftsState(
      shifts: shifts ?? this.shifts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMonth: isLoadingMonth ?? this.isLoadingMonth,
      error: error,
      loadedMonths: loadedMonths ?? this.loadedMonths,
    );
  }

  /// Obtiene los turnos de un empleado para un mes específico
  List<Shift> getMonthlyShifts(DateTime month) {
    return shifts.where((shift) {
      return shift.date.year == month.year && shift.date.month == month.month;
    }).toList();
  }

  /// Busca un turno por ID
  Shift? getShiftById(String shiftId) {
    try {
      return shifts.firstWhere((shift) => shift.id == shiftId);
    } catch (e) {
      return null;
    }
  }
}

class EmployeeShiftsViewModel extends Notifier<EmployeeShiftsState> {
  EmployeeShiftsViewModel(this.employeeId);

  final String employeeId;

  @override
  EmployeeShiftsState build() {
    return const EmployeeShiftsState();
  }

  /// Carga los turnos del mes actual inicialmente
  Future<void> loadInitialShifts({DateTime? month}) async {
    state = state.copyWith(isLoading: true, error: null);
    final targetMonth = month ?? DateTime.now();

    try {
      // Cargar turnos del mes actual
      await loadMonthShifts(targetMonth);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los turnos: $e',
      );
    }
  }

  /// Carga los turnos de un mes específico si no están ya en caché
  Future<void> loadMonthShifts(DateTime month) async {
    // Clave para identificar el mes (formato: YYYY-MM)
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Si ya cargamos este mes, salir
    if (state.loadedMonths.contains(monthKey)) {
      return;
    }

    state = state.copyWith(isLoadingMonth: true);

    try {
      final shiftService = ref.read(shiftServiceProvider);

      // Cargar turnos del mes específico
      final monthShifts = await shiftService.getMonthlyShifts(
        employeeId,
        month,
      );

      // Combinar con turnos ya cargados de otros meses
      final allShifts = [...state.shifts, ...monthShifts];

      // Ordenar por fecha
      allShifts.sort((a, b) => a.date.compareTo(b.date));

      // Marcar este mes como cargado
      final updatedLoadedMonths = {...state.loadedMonths, monthKey};

      state = state.copyWith(
        shifts: allShifts,
        loadedMonths: updatedLoadedMonths,
        isLoadingMonth: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMonth: false,
        error: 'Error al cargar turnos del mes: $e',
      );
    }
  }

  /// Añade o actualiza un turno en el estado local
  void updateShift(Shift shift) {
    // Buscar si ya existe el turno
    final existingIndex = state.shifts.indexWhere((s) => s.id == shift.id);

    List<Shift> updatedShifts;
    if (existingIndex >= 0) {
      // Actualizar turno existente
      updatedShifts = [...state.shifts];
      updatedShifts[existingIndex] = shift;
    } else {
      // Añadir nuevo turno
      updatedShifts = [...state.shifts, shift];
    }

    // Ordenar por fecha
    updatedShifts.sort((a, b) => a.date.compareTo(b.date));

    state = state.copyWith(shifts: updatedShifts);
  }

  /// Elimina un turno del estado local
  void removeShift(String shiftId) {
    final updatedShifts = state.shifts.where((s) => s.id != shiftId).toList();
    state = state.copyWith(shifts: updatedShifts);
  }
}

final employeeShiftsViewModelProvider = NotifierProvider.family<
    EmployeeShiftsViewModel,
    EmployeeShiftsState,
    String>(EmployeeShiftsViewModel.new);
