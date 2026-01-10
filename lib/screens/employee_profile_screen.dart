import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/viewmodels/employee_profile_viewmodel.dart';
import 'package:timely/config/providers.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/color_utils.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends ConsumerState<EmployeeProfileScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.microtask(() {
      ref
          .read(employeeProfileViewModelProvider(widget.employeeId).notifier)
          .loadEmployeeProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(
      employeeProfileViewModelProvider(widget.employeeId),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
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

  Widget _buildContent(ThemeData theme, EmployeeProfileState state) {
    if (state.employee == null) {
      return Center(
        child: Text(
          'No se encontró el empleado',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final employee = state.employee!;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(employeeProfileViewModelProvider(widget.employeeId).notifier)
            .loadEmployeeProfile();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            _buildProfileHeader(theme, employee),

            // Shifts Calendar
            _buildShiftsCalendar(theme, state),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, employee) {
    return IntrinsicHeight(
      child: Row(
        spacing: 16,
        children: [
          Expanded(
            flex: 3,
            child: CustomCard(
              padding: 24,
              child: Row(
                spacing: 16,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage: employee.avatarUrl != null
                        ? NetworkImage(employee.avatarUrl!)
                        : null,
                    child: employee.avatarUrl == null
                        ? Text(
                            employee.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${employee.id.substring(0, 8)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: CustomCard(
              padding: 24,
              onTap: () {
                context.push(
                  '/employee/${widget.employeeId}/registrations',
                  extra: {'employeeName': employee.fullName},
                );
              },
              child: Column(
                spacing: 6,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    'Historial',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Ver registros',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsCalendar(ThemeData theme, EmployeeProfileState state) {
    // Create a map of dates to shifts for quick lookup
    final shiftsByDate = <DateTime, Shift>{};
    for (var shift in state.upcomingShifts) {
      final dateKey = DateTime(
        shift.date.year,
        shift.date.month,
        shift.date.day,
      );
      shiftsByDate[dateKey] = shift;
    }

    final selectedShift = _selectedDay != null
        ? shiftsByDate[DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
          )]
        : null;

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and view selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 8,
              children: [
                Text(
                  'Mis Turnos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildShiftTypeLegendTooltip(theme),
              ],
            ),
            _buildViewModeSelector(theme),
          ],
        ),

        // Calendar
        if (state.isLoadingShifts)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          )
        else
          CustomCard(
            padding: 0,
            child: TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  DateTimeUtils.isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'es_ES',
              daysOfWeekHeight: 40,
              rowHeight: _calendarFormat == CalendarFormat.week ? 68 : 58,
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
                weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
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
                defaultBuilder: (context, date, focusedDay) {
                  final dateKey = DateTime(date.year, date.month, date.day);
                  final shift = shiftsByDate[dateKey];

                  if (shift != null) {
                    final isSelected = DateTimeUtils.isSameDay(
                      _selectedDay,
                      date,
                    );
                    final isToday = DateTimeUtils.isSameDay(
                      DateTime.now(),
                      date,
                    );
                    final shiftColor = _getShiftTypeColorById(
                      shift.shiftTypeId,
                    );

                    final margin = _calendarFormat == CalendarFormat.week
                        ? 5.0
                        : 4.0;
                    final borderWidth = _calendarFormat == CalendarFormat.week
                        ? (isToday ? 2.5 : 2.0)
                        : (isToday ? 2.5 : 1.8);

                    return Container(
                      margin: EdgeInsets.all(margin),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : shiftColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : shiftColor,
                          width: borderWidth,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
                todayBuilder: (context, date, focusedDay) {
                  final dateKey = DateTime(date.year, date.month, date.day);
                  final shift = shiftsByDate[dateKey];

                  if (shift != null) {
                    // If there's a shift today, use the defaultBuilder logic
                    return null;
                  }

                  final margin = _calendarFormat == CalendarFormat.week
                      ? 5.0
                      : 4.0;

                  return Container(
                    margin: EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, date, focusedDay) {
                  final dateKey = DateTime(date.year, date.month, date.day);
                  final shift = shiftsByDate[dateKey];

                  if (shift != null) {
                    // If there's a shift on selected day, use the defaultBuilder logic
                    return null;
                  }

                  final margin = _calendarFormat == CalendarFormat.week
                      ? 5.0
                      : 4.0;

                  return Container(
                    margin: EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                disabledBuilder: (context, date, focusedDay) {
                  final margin = _calendarFormat == CalendarFormat.week
                      ? 5.0
                      : 4.0;

                  return Container(
                    margin: EdgeInsets.all(margin),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  );
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
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
            ),
          ),

        // Selected day shift details
        if (selectedShift != null)
          _buildSelectedShiftCard(theme, selectedShift)
        else if (_selectedDay != null)
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
                    'No hay turno programado para este día',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShiftTypeLegendTooltip(ThemeData theme) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        return GestureDetector(
          onTap: () {
            _showShiftTypesOverlay(context, theme, config.shiftTypes);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.info_outline,
              size: 26,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showShiftTypesOverlay(
    BuildContext context,
    ThemeData theme,
    List<dynamic> shiftTypes,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                ...shiftTypes.map((shiftType) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: shiftType.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            spacing: 6,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shiftType.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    shiftType.startTime,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (shiftType.pauseTime != null &&
                                      shiftType.resumeTime != null) ...[
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    Text(
                                      shiftType.pauseTime!,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    Text(
                                      shiftType.resumeTime!,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  Text(
                                    shiftType.endTime,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedShiftCard(ThemeData theme, Shift shift) {
    final shiftColor = _getShiftTypeColorById(shift.shiftTypeId);
    final pauseTime = _getShiftPauseTime(shift.shiftTypeId);
    final resumeTime = _getShiftResumeTime(shift.shiftTypeId);
    final hasPause = pauseTime != null && resumeTime != null;
    final targetHours = _getTargetHours();

    return CustomCard(
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with date and shift type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  Icon(Icons.event, color: shiftColor, size: 20),
                  Text(
                    DateFormat('EEEE, d MMMM', 'es_ES').format(shift.date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                  color: shiftColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Text(
                      _getShiftTypeName(shift.shiftTypeId),
                      style: TextStyle(
                        color: shiftColor,
                        fontWeight: FontWeight.bold,
                        fontSize: theme.textTheme.bodyMedium?.fontSize,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        color: shiftColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      targetHours,
                      style: TextStyle(
                        color: shiftColor,
                        fontWeight: FontWeight.w600,
                        fontSize: theme.textTheme.bodyMedium?.fontSize,
                      ),
                    ),
                  ],
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
                  _getShiftStartTime(shift.shiftTypeId),
                  Icons.login,
                  shiftColor,
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
                    pauseTime,
                    Icons.pause_circle_outline,
                    shiftColor,
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
                    resumeTime,
                    Icons.play_circle_outline,
                    shiftColor,
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
                  _getShiftEndTime(shift.shiftTypeId),
                  Icons.logout,
                  shiftColor,
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
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          Text(
            time,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: theme.textTheme.bodyLarge?.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  String _getTargetHours() {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final hours = config.targetTimeMinutes ~/ 60;
        final minutes = config.targetTimeMinutes % 60;
        if (minutes == 0) {
          return '${hours}h';
        }
        return '${hours}h ${minutes}m';
      },
      loading: () => '--h',
      error: (_, _) => '--h',
    );
  }

  // Helper methods to get shift type info from config
  String _getShiftTypeName(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.name ?? shiftTypeId;
      },
      loading: () => shiftTypeId,
      error: (_, _) => shiftTypeId,
    );
  }

  Color _getShiftTypeColorById(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.color ?? ColorUtils.greyColor;
      },
      loading: () => ColorUtils.greyColor,
      error: (_, _) => ColorUtils.greyColor,
    );
  }

  String _getShiftStartTime(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.startTime ?? '--:--';
      },
      loading: () => '--:--',
      error: (_, _) => '--:--',
    );
  }

  String _getShiftEndTime(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.endTime ?? '--:--';
      },
      loading: () => '--:--',
      error: (_, _) => '--:--',
    );
  }

  String? _getShiftPauseTime(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.pauseTime;
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }

  String? _getShiftResumeTime(String shiftTypeId) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final shiftType = config.getShiftTypeById(shiftTypeId);
        return shiftType?.resumeTime;
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }

  Widget _buildViewModeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            theme,
            Icons.view_week,
            CalendarFormat.week,
            'Semana',
          ),
          _buildViewModeButton(
            theme,
            Icons.calendar_month,
            CalendarFormat.month,
            'Mes',
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    ThemeData theme,
    IconData icon,
    CalendarFormat mode,
    String tooltip,
  ) {
    final isSelected = _calendarFormat == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _calendarFormat = mode;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
