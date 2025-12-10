import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/viewmodels/employee_detail_viewmodel.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';
import 'package:timely/widgets/employee_detail_appbar.dart';
import 'package:timely/widgets/time_gauge.dart';

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
      appBar: EmployeeDetailAppBar(
        employeeName: detailState.employee?.fullName ?? 'Cargando...',
        employeeImageUrl: detailState.employee?.avatarUrl,
        onBackPressed: () => context.pop(),
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

    // MyTheme from themeViewModel
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeState = ref.watch(themeViewModelProvider);
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    final myTheme = themes[currentThemeType]!;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
            .refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        child: Column(
          spacing: 28,
          children: [
            CustomCard(
              padding: 24,
              width: double.infinity,
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleText("Registro actual:"),
                  Center(
                    child: TimeGauge(
                      registration: registration,
                      size: 400,
                      strokeWidth: 50,
                      mode: GaugeMode.time,
                      myTheme: myTheme,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons / Completed message - MISMO TAMAÑO
            if (registration == null)
              _buildStartButton(context, theme)
            else if (hasActiveRegistration)
              _buildEndButton(context, theme, myTheme)
            else
              _buildCompletedMessage(theme, registration, myTheme),

            // Registration detail list
            if (registration != null) ...[
              _buildRegistrationDetails(registration, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationDetails(dynamic registration, ThemeData theme) {
    return CustomCard(
      width: double.infinity,
      child: Column(
        spacing: 8,
        children: [
          Column(
            children: [
              Text(
                'Hora de inicio',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 18,
                ),
              ),
              Text(
                _formatTime(registration.startTime),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          if (registration.endTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          if (registration.endTime != null)
            Column(
              spacing: 8,
              children: [
                Text(
                  'Hora de fin',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatTime(registration.endTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStartButton(BuildContext context, ThemeData theme) {
    return CustomCard(
      width: double.infinity,
      onTap: () => _startDayOfWork(context),
      padding: 24,
      color: theme.colorScheme.primary,
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 28),
          SubtitleText('Comenzar jornada'),
        ],
      ),
    );
  }

  Widget _buildEndButton(
    BuildContext context,
    ThemeData theme,
    MyTheme myTheme,
  ) {
    return CustomCard(
      width: double.infinity,
      onTap: () => _showEndConfirmation(context, myTheme),
      padding: 24,
      color: theme.colorScheme.error,
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stop, size: 28, color: theme.colorScheme.onError),
          SubtitleText('Finalizar jornada', color: theme.colorScheme.onError),
        ],
      ),
    );
  }

  Widget _buildCompletedMessage(
    ThemeData theme,
    TimeRegistration registration,
    MyTheme myTheme,
  ) {
    const targetMinutes = 420; // 7 horas
    final totalMinutes = registration.totalMinutes;
    final diffMinutes =
        targetMinutes -
        totalMinutes; // `-` means over time; `+` means under time

    final status = registration.status;
    Color statusColor;
    IconData statusIcon;
    final String statusText = 'Jornada completada';

    String timeText;

    if (status == TimeRegistrationStatus.green) {
      statusColor = Color(
        int.parse(myTheme.colorGreen.replaceFirst('#', '0xff')),
      );
      statusIcon = Icons.check_circle;
      timeText = 'Tiempo realizado: ';
      if (diffMinutes < 0) {
        timeText += '+${DateTimeUtils.minutesToReadable(diffMinutes.abs())}';
      } else if (diffMinutes > 0) {
        timeText += '-${DateTimeUtils.minutesToReadable(diffMinutes.abs())}';
      } else {
        timeText += DateTimeUtils.minutesToReadable(diffMinutes.abs());
      }
    } else if (status == TimeRegistrationStatus.orange) {
      statusColor = Color(
        int.parse(myTheme.colorOrange.replaceFirst('#', '0xff')),
      );
      statusIcon = Icons.warning_rounded;
      timeText = diffMinutes < 0 ? 'Tiempo excedido: ' : 'Tiempo restante: ';
      timeText += diffMinutes < 0
          ? '+${DateTimeUtils.minutesToReadable(diffMinutes.abs())}'
          : '-${DateTimeUtils.minutesToReadable(diffMinutes.abs())}';
    } else {
      statusColor = Color(
        int.parse(myTheme.colorRed.replaceFirst('#', '0xff')),
      );
      statusIcon = Icons.error_rounded;
      timeText = diffMinutes < 0 ? 'Tiempo excedido: ' : 'Tiempo restante: ';
      timeText += diffMinutes < 0
          ? '+${DateTimeUtils.minutesToReadable(diffMinutes.abs())}'
          : '-${DateTimeUtils.minutesToReadable(diffMinutes.abs())}';
    }

    return SizedBox(
      width: double.infinity,
      child: CustomCard(
        padding: 28,
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleText(statusText),
                  const SizedBox(height: 4),
                  SubtitleText(timeText, color: statusColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDayOfWork(BuildContext context) async {
    try {
      await ref
          .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
          .startWorkday();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jornada iniciada correctamente'),
            backgroundColor: Color(0xFF46B56C),
            showCloseIcon: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD64C4C),
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  Future<void> _showEndConfirmation(
    BuildContext context,
    MyTheme myTheme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TitleText(
          '¿Finalizar jornada?',
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.all(24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const SubtitleText(
            'Esta acción no se puede revertir. Una vez finalices tu jornada laboral, '
            'no podrás volver a iniciarla hoy.',
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          CustomCard(
            onTap: () => Navigator.of(context).pop(false),
            elevation: 0,
            color: Color(
              int.parse(myTheme.inactiveColor.replaceFirst('#', '0xee')),
            ),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(
                    int.parse(
                      myTheme.onInactiveColor.replaceFirst('#', '0xff'),
                    ),
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          CustomCard(
            onTap: () => Navigator.of(context).pop(true),
            elevation: 0,
            color: Color(int.parse(myTheme.colorRed.replaceFirst('#', '0xff'))),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                'Finalizar',
                style: TextStyle(
                  color: Color(
                    int.parse(myTheme.onRedColor.replaceFirst('#', '0xff')),
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
              showCloseIcon: true,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFD64C4C),
              showCloseIcon: true,
            ),
          );
        }
      }
    }
  }
}
