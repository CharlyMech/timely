import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_detail_viewmodel.dart';
import 'package:timely/widgets/time_registration_widget.dart';

class TimeRegistrationDetailScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const TimeRegistrationDetailScreen({super.key, required this.employeeId});

  @override
  ConsumerState<TimeRegistrationDetailScreen> createState() =>
      _TimeRegistrationDetailScreenState();
}

class _TimeRegistrationDetailScreenState
    extends ConsumerState<TimeRegistrationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load employee data at the beginning
    Future.microtask(() {
      ref
          .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
          .loadEmployee();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailState = ref.watch(
      employeeDetailViewModelProvider(widget.employeeId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(detailState.employee?.fullName ?? 'Cargando...'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailState.isLoading
          ? _buildLoadingState(theme)
          : detailState.error != null
          ? _buildErrorState(theme, detailState.error!)
          : _buildDetailContent(context, theme, detailState),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
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
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(
                      employeeDetailViewModelProvider(
                        widget.employeeId,
                      ).notifier,
                    )
                    .loadEmployee();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    ThemeData theme,
    EmployeeDetailState state,
  ) {
    final employee = state.employee;
    if (employee == null) return const SizedBox.shrink();

    final registration = employee.currentRegistration;
    final hasActiveRegistration = registration?.isActive ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
            .refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 64,
              backgroundColor: theme.primaryColor,
              child: Text(
                _getInitials(employee.fullName),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              employee.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registro de hoy:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            TimeRegistrationWidget(
              registration: registration,
              size: 200,
              showDetails: true,
            ),
            const SizedBox(height: 48),
            if (registration == null)
              _buildStartButton(context, theme)
            else if (hasActiveRegistration)
              _buildEndButton(context, theme)
            else
              _buildCompletedMessage(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showStartConfirmation(context),
        icon: const Icon(Icons.play_arrow, size: 28),
        label: const Text('Comenzar jornada'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF46B56C),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEndButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showEndConfirmation(context),
        icon: const Icon(Icons.stop, size: 28),
        label: const Text('Finalizar jornada'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFFD64C4C),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletedMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF46B56C), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jornada finalizada',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El registro de hoy ha sido completado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStartConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar jornada'),
        content: const Text(
          '¿Estás seguro/a de que quieres comenzar tu jornada laboral?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
            .startWorkday();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jornada iniciada correctamente'),
              backgroundColor: Color(0xFF46B56C),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFD64C4C),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEndConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar jornada?'),
        content: const Text(
          'Esta acción no se puede revertir. Una vez finalices tu jornada laboral, '
          'no podrás volver a iniciarla hoy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
            .endWorkday();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jornada finalizada correctamente'),
              backgroundColor: Color(0xFF46B56C),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFD64C4C),
            ),
          );
        }
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
