import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';
import 'package:timely/widgets/employee_card.dart';
import 'package:timely/widgets/staff_appbar.dart';
import 'dart:async';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  Timer? _inactivityTimer;
  static const _inactivityDuration = Duration(minutes: 5);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _onInactivityTimeout);
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _onInactivityTimeout() {
    if (mounted) {
      context.go('/splash');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    _resetInactivityTimer();
  }

  void _onSearchCleared() {
    setState(() {
      _searchQuery = '';
    });
    _resetInactivityTimer();
  }

  List<dynamic> _filterEmployees(List<dynamic> employees) {
    if (_searchQuery.isEmpty) {
      return employees;
    }

    return employees.where((employee) {
      // SAFE VERSION: Only search by fullName which we know exists
      try {
        final fullName = employee.fullName?.toString().toLowerCase() ?? '';
        return fullName.contains(_searchQuery);
      } catch (e) {
        // If there's any error accessing the employee, exclude it from results
        print('Error filtering employee: $e');
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeViewModelProvider);

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: StaffAppBar(
          onSearchChanged: _onSearchChanged,
          onSearchCleared: _onSearchCleared,
        ),
        body: employeeState.isLoading
            ? _buildLoadingState(theme)
            : employeeState.error != null
            ? _buildErrorState(theme, employeeState.error!)
            : _buildEmployeeGrid(_filterEmployees(employeeState.employees)),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando personal...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _resetInactivityTimer();
                ref.read(employeeViewModelProvider.notifier).loadEmployees();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeGrid(List<dynamic> employees) {
    if (employees.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _resetInactivityTimer();
        await ref.read(employeeViewModelProvider.notifier).refreshEmployees();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return EmployeeCard(
                employee: employee,
                onTap: () {
                  _resetInactivityTimer();
                  context.push('/employee/${employee.id}');
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptySearchState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) {
      return 1; // Mobile
    } else if (width < 900) {
      return 3; // Tablet small
    } else if (width < 1200) {
      return 4; // Tablet large
    } else {
      return 5; // Desktop
    }
  }
}
