import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/viewmodels/employee_registrations_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/color_utils.dart';

class EmployeeRegistrationsScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeRegistrationsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  ConsumerState<EmployeeRegistrationsScreen> createState() =>
      _EmployeeRegistrationsScreenState();
}

class _EmployeeRegistrationsScreenState
    extends ConsumerState<EmployeeRegistrationsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(
            employeeRegistrationsViewModelProvider(widget.employeeId).notifier,
          )
          .loadInitialRegistrations(month: _focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(
      employeeRegistrationsViewModelProvider(widget.employeeId),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Registros de ${widget.employeeName}',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? _buildLoadingState(theme)
          : state.error != null
          ? _buildErrorState(theme, state.error!)
          : _buildContent(theme, state),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, EmployeeRegistrationsState state) {
    if (state.registrations.isEmpty) {
      return Center(
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            Text(
              'No hay registros disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Map registrations by date for easy lookup
    final registrationsByDate = <DateTime, TimeRegistration>{};
    for (var registration in state.registrations) {
      final date = registration.startTime;
      final dateKey = DateTime(date.year, date.month, date.day);
      registrationsByDate[dateKey] = registration;
    }

    final selectedRegistration = _selectedDay != null
        ? registrationsByDate[DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
          )]
        : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 20,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  Expanded(
                    child: Text(
                      'Registros totales de ${_getMonthName(_focusedDay)}: ${state.monthlyCount}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            Container(
              height: 410,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TableCalendar(
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      DateTimeUtils.isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  locale: 'es_ES',
                  daysOfWeekHeight: 40,
                  rowHeight: 58,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    headerPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    defaultTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    disabledTextStyle: TextStyle(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  enabledDayPredicate: (day) {
                    final configAsync = ref.read(appConfigProvider);
                    return configAsync.when(
                      data: (config) => config.isWorkingDay(day),
                      loading: () => true,
                      error: (_, _) => true,
                    );
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final dateKey = DateTime(date.year, date.month, date.day);
                      final registration = registrationsByDate[dateKey];

                      if (registration != null) {
                        final configAsync = ref.watch(appConfigProvider);
                        final targetMinutes = configAsync.when(
                          data: (config) => config.targetTimeMinutes,
                          loading: () => 480,
                          error: (_, _) => 480,
                        );
                        final warningThreshold = configAsync.when(
                          data: (config) => config.warningThresholdMinutes,
                          loading: () => 15,
                          error: (_, _) => 15,
                        );
                        final redThreshold = configAsync.when(
                          data: (config) => config.redThresholdMinutes,
                          loading: () => 60,
                          error: (_, _) => 60,
                        );

                        final statusColor = _getStatusColorByTarget(
                          theme,
                          registration.totalMinutes,
                          targetMinutes,
                          warningThreshold,
                          redThreshold,
                        );

                        return Positioned(
                          bottom: 2,
                          child: Container(
                            width: 18,
                            height: 2,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!DateTimeUtils.isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    // Load registrations for new month
                    ref
                        .read(
                          employeeRegistrationsViewModelProvider(
                            widget.employeeId,
                          ).notifier,
                        )
                        .loadMonthRegistrations(focusedDay);
                  },
                ),
              ),
            ),

            // Selected day registration details
            if (selectedRegistration != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(_selectedDay!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildRegistrationCard(theme, selectedRegistration),
            ] else if (_selectedDay != null) ...[
              CustomCard(
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: Text(
                        'No hay registro para el ${_formatDate(_selectedDay!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecciona un día en el calendario para ver el registro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Load more button
            if (state.hasMore) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: state.isLoadingMore
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(
                                employeeRegistrationsViewModelProvider(
                                  widget.employeeId,
                                ).notifier,
                              )
                              .loadMoreRegistrations();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cargar más registros'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(
    ThemeData theme,
    TimeRegistration registration,
  ) {
    final configAsync = ref.watch(appConfigProvider);
    final targetMinutes = configAsync.when(
      data: (config) => config.targetTimeMinutes,
      loading: () => 480,
      error: (_, _) => 480,
    );
    final warningThreshold = configAsync.when(
      data: (config) => config.warningThresholdMinutes,
      loading: () => 15,
      error: (_, _) => 15,
    );
    final redThreshold = configAsync.when(
      data: (config) => config.redThresholdMinutes,
      loading: () => 60,
      error: (_, _) => 60,
    );

    final statusColor = _getStatusColorByTarget(
      theme,
      registration.totalMinutes,
      targetMinutes,
      warningThreshold,
      redThreshold,
    );
    final hoursWorked = _formatDuration(registration.totalMinutes);
    final hasPause =
        registration.pauseTime != null && registration.resumeTime != null;
    final shiftTypeInfo = _getShiftTypeInfo(registration.shiftId);
    final shiftTypeName = shiftTypeInfo['name'] as String;
    final shiftTypeColor = shiftTypeInfo['color'] as Color;

    return CustomCard(
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  Icon(Icons.work_outline, size: 20, color: shiftTypeColor),
                  Text(
                    'Turno: $shiftTypeName',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: shiftTypeColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: $hoursWorked',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),

          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  'Entrada',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (hasPause) ...[
                Expanded(
                  child: Text(
                    'Pausa',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Reanuda',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  'Salida',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          Row(
            spacing: 8,
            children: [
              Expanded(
                child: _buildTimeChip(
                  theme,
                  _formatTime(registration.startTime),
                  Icons.login,
                  theme.colorScheme.primary,
                  registration.startTime,
                  registration.shiftId,
                  'start',
                  warningThreshold,
                  redThreshold,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              if (hasPause) ...[
                Expanded(
                  child: _buildTimeChip(
                    theme,
                    _formatTime(registration.pauseTime!),
                    Icons.pause_circle_outline,
                    theme.colorScheme.primary,
                    registration.pauseTime!,
                    registration.shiftId,
                    'pause',
                    warningThreshold,
                    redThreshold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                Expanded(
                  child: _buildTimeChip(
                    theme,
                    _formatTime(registration.resumeTime!),
                    Icons.play_circle_outline,
                    theme.colorScheme.primary,
                    registration.resumeTime!,
                    registration.shiftId,
                    'resume',
                    warningThreshold,
                    redThreshold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
              Expanded(
                child: _buildTimeChip(
                  theme,
                  registration.endTime != null
                      ? _formatTime(registration.endTime!)
                      : 'En curso',
                  Icons.logout,
                  theme.colorScheme.secondary,
                  registration.endTime,
                  registration.shiftId,
                  'end',
                  warningThreshold,
                  redThreshold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(
    ThemeData theme,
    String time,
    IconData icon,
    Color iconColor,
    DateTime? actualTime,
    String shiftId,
    String timeType,
    int warningThreshold,
    int redThreshold,
  ) {
    // Calculate time compliance indicator and get expected time
    Color? indicatorColor;
    String? expectedTimeStr;

    if (actualTime != null) {
      final configAsync = ref.watch(appConfigProvider);

      final result = configAsync.when(
        data: (config) {
          final shiftType = config.getShiftTypeById(shiftId);
          if (shiftType == null) return {'color': null, 'expected': null};

          // Get expected time based on time type
          String? expected;
          switch (timeType) {
            case 'start':
              expected = shiftType.startTime;
              break;
            case 'pause':
              expected = shiftType.pauseTime;
              break;
            case 'resume':
              expected = shiftType.resumeTime;
              break;
            case 'end':
              expected = shiftType.endTime;
              break;
          }

          if (expected == null) return {'color': null, 'expected': null};

          // Parse expected time and compare with actual
          final timeParts = expected.split(':');
          final expectedHour = int.parse(timeParts[0]);
          final expectedMinute = int.parse(timeParts[1]);

          // Create DateTime with same date but expected time
          final expectedTime = DateTime(
            actualTime.year,
            actualTime.month,
            actualTime.day,
            expectedHour,
            expectedMinute,
          );

          // Calculate difference in minutes
          final differenceMinutes = actualTime
              .difference(expectedTime)
              .inMinutes
              .abs();

          // Determine color based on threshold
          Color? color;
          if (differenceMinutes <= warningThreshold) {
            color = null; // No indicator needed, within acceptable range
          } else if (differenceMinutes <= redThreshold) {
            color = ColorUtils.orangeColor; // Warning threshold exceeded
          } else {
            color = ColorUtils.redColor; // Red threshold exceeded
          }

          return {'color': color, 'expected': expected};
        },
        loading: () => {'color': null, 'expected': null},
        error: (_, _) => {'color': null, 'expected': null},
      );

      indicatorColor = result['color'] as Color?;
      expectedTimeStr = result['expected'] as String?;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor != null
              ? indicatorColor.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: indicatorColor != null ? 2 : 1,
        ),
      ),
      child: Column(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          Text(
            time,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: theme.textTheme.bodyLarge?.fontSize,
            ),
          ),
          if (expectedTimeStr != null && actualTime != null)
            Text(
              '($expectedTimeStr)',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColorByTarget(
    ThemeData theme,
    int actualMinutes,
    int targetMinutes,
    int warningThreshold,
    int redThreshold,
  ) {
    // Calculate the difference from target
    final difference = (targetMinutes - actualMinutes).abs();

    // Green: within warning threshold of target
    // Orange: between warning and red threshold
    // Red: beyond red threshold
    if (difference <= warningThreshold) {
      return ColorUtils.greenColor;
    } else if (difference <= redThreshold) {
      return ColorUtils.orangeColor;
    } else {
      return ColorUtils.redColor;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _getMonthName(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Map<String, dynamic> _getShiftTypeInfo(String shiftId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftId);
        return {
          'name': shiftType?.name ?? 'Turno',
          'color': shiftType?.color ?? ColorUtils.greyColor,
          'shiftType': shiftType,
        };
      },
      loading: () => {
        'name': 'Turno',
        'color': ColorUtils.greyColor,
        'shiftType': null,
      },
      error: (_, _) => {
        'name': 'Turno',
        'color': ColorUtils.greyColor,
        'shiftType': null,
      },
    );
  }
}
