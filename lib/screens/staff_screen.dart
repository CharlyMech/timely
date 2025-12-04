import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';
import 'package:timely/widgets/employee_card.dart';
import 'dart:async';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  Timer? _inactivityTimer;
  static const _inactivityDuration = Duration(minutes: 5);

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

  /// Inicia el temporizador de inactividad
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _onInactivityTimeout);
  }

  /// Reinicia el temporizador cuando hay actividad
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  /// Callback cuando se detecta inactividad
  void _onInactivityTimeout() {
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeViewModelProvider);

    return GestureDetector(
      // Detectar cualquier interacción para resetear el timer
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal'),
          centerTitle: true,
          actions: [
            // Botón de búsqueda (opcional)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _resetInactivityTimer();
                // TODO: Implementar búsqueda
              },
            ),
          ],
        ),
        body: employeeState.isLoading
            ? _buildLoadingState(theme)
            : employeeState.error != null
            ? _buildErrorState(theme, employeeState.error!)
            : _buildEmployeeGrid(employeeState.employees),
      ),
    );
  }

  /// Widget de carga
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de error
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

  /// Grid de empleados con RefreshIndicator
  Widget _buildEmployeeGrid(List<dynamic> employees) {
    return RefreshIndicator(
      onRefresh: () async {
        _resetInactivityTimer();
        await ref.read(employeeViewModelProvider.notifier).refreshEmployees();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determinar número de columnas según el ancho disponible
          final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Ratio ancho/alto de las cards
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

  /// Calcula el número de columnas según el ancho de pantalla
  int _calculateCrossAxisCount(double width) {
    if (width < 600) {
      return 2; // Móvil: 2 columnas
    } else if (width < 900) {
      return 3; // Tablet pequeña: 3 columnas
    } else if (width < 1200) {
      return 4; // Tablet grande: 4 columnas
    } else {
      return 5; // Desktop: 5 columnas
    }
  }
}
