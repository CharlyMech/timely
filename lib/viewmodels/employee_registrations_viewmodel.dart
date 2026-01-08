import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/time_registration.dart';

class EmployeeRegistrationsState {
  final List<TimeRegistration> registrations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int totalCount;
  final int monthlyCount;
  final bool hasMore;
  final DateTime? currentMonth;

  const EmployeeRegistrationsState({
    this.registrations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.totalCount = 0,
    this.monthlyCount = 0,
    this.hasMore = true,
    this.currentMonth,
  });

  EmployeeRegistrationsState copyWith({
    List<TimeRegistration>? registrations,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? totalCount,
    int? monthlyCount,
    bool? hasMore,
    DateTime? currentMonth,
  }) {
    return EmployeeRegistrationsState(
      registrations: registrations ?? this.registrations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      monthlyCount: monthlyCount ?? this.monthlyCount,
      hasMore: hasMore ?? this.hasMore,
      currentMonth: currentMonth ?? this.currentMonth,
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
  static const int _pageSize = 100;
  int _currentOffset = 0;

  @override
  EmployeeRegistrationsState build() {
    return const EmployeeRegistrationsState();
  }

  Future<void> loadInitialRegistrations({DateTime? month}) async {
    state = state.copyWith(isLoading: true, error: null);
    final targetMonth = month ?? DateTime(2025, 12, 1);

    try {
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);
      final registrations = await timeRegistrationService
          .getEmployeeRegistrations(employeeId, limit: _pageSize, offset: 0);
      final totalCount =
          await timeRegistrationService.getTotalRegistrationsCount(employeeId);

      _currentOffset = _pageSize;

      final monthlyCount = registrations.where((reg) {
        final regDate = reg.startTime;
        return regDate.year == targetMonth.year && regDate.month == targetMonth.month;
      }).length;

      state = state.copyWith(
        registrations: registrations,
        isLoading: false,
        totalCount: totalCount,
        monthlyCount: monthlyCount,
        hasMore: registrations.length < totalCount,
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
    // Update monthly count when month changes
    final monthlyCount = state.registrations.where((reg) {
      final regDate = reg.startTime;
      return regDate.year == month.year && regDate.month == month.month;
    }).length;

    state = state.copyWith(
      currentMonth: month,
      monthlyCount: monthlyCount,
    );
  }

  Future<void> loadMoreRegistrations() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final timeRegistrationService = ref.read(timeRegistrationServiceProvider);
      final newRegistrations =
          await timeRegistrationService.getEmployeeRegistrations(
        employeeId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      _currentOffset += _pageSize;

      final allRegistrations = [...state.registrations, ...newRegistrations];

      state = state.copyWith(
        registrations: allRegistrations,
        isLoadingMore: false,
        hasMore: allRegistrations.length < state.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Error al cargar más registros: $e',
      );
    }
  }
}

final employeeRegistrationsViewModelProvider = NotifierProvider.family<
    EmployeeRegistrationsViewModel,
    EmployeeRegistrationsState,
    String>(EmployeeRegistrationsViewModel.new);
