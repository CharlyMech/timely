/// Displays an employee's historical time registrations in a calendar view.
///
/// This library provides [EmployeeRegistrationsScreen], a screen that shows
/// daily work records, compliance status, and shift details through an
/// interactive monthly calendar interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/color_utils.dart';
import 'package:timely/viewmodels/employee_registrations_viewmodel.dart';
import 'package:timely/viewmodels/employee_shifts_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/responsive_utils.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/inactivity_wrapper.dart';

/// A screen that displays an employee's time registrations in a calendar view.
///
/// This screen shows historical time registrations for a specific employee,
/// allowing users to view daily work records, compliance status, and shift details
/// through an interactive monthly calendar interface.
class EmployeeRegistrationsScreen extends ConsumerStatefulWidget {
  /// The unique identifier of the employee whose registrations to display.
  final String employeeId;

  /// The display name of the employee.
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

/// State for [EmployeeRegistrationsScreen] that manages calendar selection and data loading.
class _EmployeeRegistrationsScreenState
    extends ConsumerState<EmployeeRegistrationsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  MyTheme get _currentTheme {
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeState = ref.watch(themeViewModelProvider);
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    return themes[currentThemeType]!;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load registrations for the current month.
      await ref
          .read(
            employeeRegistrationsViewModelProvider(widget.employeeId).notifier,
          )
          .loadInitialRegistrations(month: _focusedDay);

      // Load shifts for the current month.
      await ref
          .read(employeeShiftsViewModelProvider(widget.employeeId).notifier)
          .loadInitialShifts(month: _focusedDay);

      // Load shifts for all months that have registrations.
      final regsState = ref.read(
        employeeRegistrationsViewModelProvider(widget.employeeId),
      );
      final uniqueMonths = <DateTime>{};
      for (var reg in regsState.registrations) {
        uniqueMonths.add(DateTime(reg.startTime.year, reg.startTime.month, 1));
      }

      // Load shifts for each unique month.
      for (var month in uniqueMonths) {
        if (month.year != _focusedDay.year ||
            month.month != _focusedDay.month) {
          await ref
              .read(employeeShiftsViewModelProvider(widget.employeeId).notifier)
              .loadMonthShifts(month);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(
      employeeRegistrationsViewModelProvider(widget.employeeId),
    );

    return InactivityWrapper(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Mis registros',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20),
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
      ),
    );
  }

  /// Builds the loading state widget with a circular progress indicator.
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
      ),
    );
  }

  /// Builds the error state widget with error message and icon.
  Widget _buildErrorState(ThemeData theme, String error) {
    final responsive = context.responsive;
    return Center(
      child: Padding(
        padding: responsive.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: responsive.responsiveValue(
                mobile: 64,
                tablet: 72,
                desktop: 80,
              ),
              color: theme.colorScheme.error,
            ),
            SizedBox(height: responsive.spacing),
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

  /// Builds the main content layout with calendar and registration details.
  ///
  /// Displays monthly registration count, calendar view with status indicators,
  /// and details for the selected day. Handles month navigation and prevents
  /// navigation to future months.
  Widget _buildContent(ThemeData theme, EmployeeRegistrationsState state) {
    final responsive = context.responsive;
    final configAsync = ref.watch(appConfigProvider);

    // Get config values
    final targetMinutes = configAsync.when(
      data: (config) => config.defaultTargetTimeMinutes,
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
        padding: responsive.screenPadding,
        child: Column(
          spacing: responsive.spacing,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing,
                vertical: responsive.spacing * 0.75,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(responsive.borderRadius),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                spacing: responsive.spacing * 0.75,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: responsive.iconSize,
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
            if (state.isLoadingMonth)
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando registros del mes...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
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
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mes',
                    },
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
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.3,
                        ),
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
                        final dateKey = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        final registration = registrationsByDate[dateKey];

                        if (registration != null) {
                          // Calculate the status using the configuration.
                          final registrationStatus = registration.getStatus(
                            targetMinutes: targetMinutes,
                            warningThreshold: warningThreshold,
                            redThreshold: redThreshold,
                          );
                          // Use the color from the registration's global status.
                          final statusColor = _getColorFromStatus(
                            registrationStatus,
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
                      // Do not allow navigation to future months.
                      final now = DateTime.now();
                      final currentMonthStart = DateTime(
                        now.year,
                        now.month,
                        1,
                      );
                      final focusedMonthStart = DateTime(
                        focusedDay.year,
                        focusedDay.month,
                        1,
                      );

                      if (focusedMonthStart.isAfter(currentMonthStart)) {
                        // If trying to navigate to a future month, revert to current month.
                        setState(() {
                          _focusedDay = now;
                        });
                        return;
                      }

                      setState(() {
                        _focusedDay = focusedDay;
                      });

                      // Load registrations and shifts for the new month.
                      ref
                          .read(
                            employeeRegistrationsViewModelProvider(
                              widget.employeeId,
                            ).notifier,
                          )
                          .loadMonthRegistrations(focusedDay);

                      ref
                          .read(
                            employeeShiftsViewModelProvider(
                              widget.employeeId,
                            ).notifier,
                          )
                          .loadMonthShifts(focusedDay);
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
              _buildRegistrationCard(
                theme,
                selectedRegistration,
                targetMinutes,
                warningThreshold,
                redThreshold,
              ),
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
          ],
        ),
      ),
    );
  }

  /// Builds a detailed card showing registration information for a specific day.
  ///
  /// Displays shift type, total hours worked, and individual time entries
  /// (start, pause, resume, end) with compliance indicators showing how
  /// closely actual times match expected shift times.
  Widget _buildRegistrationCard(
    ThemeData theme,
    TimeRegistration registration,
    int targetMinutes,
    int warningThreshold,
    int redThreshold,
  ) {
    // Calculate the registraton status
    final registrationStatus = registration.getStatus(
      targetMinutes: targetMinutes,
      warningThreshold: warningThreshold,
      redThreshold: redThreshold,
    );
    // Use registration global state's color
    final statusColor = _getColorFromStatus(registrationStatus);
    final hoursWorked = DateTimeUtils.minutesToReadable(
      registration.totalMinutes,
    );
    final shiftTypeInfo = _getShiftTypeInfo(registration.shiftId);
    final shiftTypeName = shiftTypeInfo['name'] as String;
    final shiftTypeColor = shiftTypeInfo['color'] as Color;
    // Check if shift type has pause configured
    final shiftTypeHasPause = shiftTypeInfo['shiftType']?.hasPauseResume ?? false;
    // Check if registration actually has pause/resume data (unexpected pause in continuous shift)
    final registrationHasPause = registration.pauseTime != null ||
        registration.resumeTime != null;
    // Show pause/resume UI if either shift type supports it OR registration has actual data
    final hasPauseResume = shiftTypeHasPause || registrationHasPause;
    // Flag to indicate unexpected pause (continuous shift with pause data)
    final isUnexpectedPause = !shiftTypeHasPause && registrationHasPause;
    final responsive = context.responsive;

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

          // Responsive layout: 2 rows on mobile with pause and resume; 1 row on tablet with pause and resume
          if (responsive.isMobile && hasPauseResume) ...[
            Row(
              spacing: 16,
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
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: _buildTimeChip(
                    theme,
                    DateTimeUtils.formatTime(registration.startTime),
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
                Expanded(
                  child: _buildTimeChip(
                    theme,
                    registration.pauseTime != null
                        ? DateTimeUtils.formatTime(registration.pauseTime!)
                        : '--:--',
                    Icons.pause_circle_outline,
                    theme.colorScheme.primary,
                    registration.pauseTime,
                    registration.shiftId,
                    'pause',
                    warningThreshold,
                    redThreshold,
                    forceWarning: isUnexpectedPause,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 16,
              children: [
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
                    registration.resumeTime != null
                        ? DateTimeUtils.formatTime(registration.resumeTime!)
                        : '--:--',
                    Icons.play_circle_outline,
                    theme.colorScheme.primary,
                    registration.resumeTime,
                    registration.shiftId,
                    'resume',
                    warningThreshold,
                    redThreshold,
                    forceWarning: isUnexpectedPause,
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
                    registration.endTime != null
                        ? DateTimeUtils.formatTime(registration.endTime!)
                        : 'En curso',
                    Icons.logout,
                    theme.colorScheme.primary,
                    registration.endTime,
                    registration.shiftId,
                    'end',
                    warningThreshold,
                    redThreshold,
                  ),
                ),
              ],
            ),
          ] else ...[
            // No pause layout for both tablet and mobile
            Row(
              spacing: 16,
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
                if (hasPauseResume) ...[
                  Expanded(
                    child: Text(
                      'Pausa',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Reanuda',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ),
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
                    DateTimeUtils.formatTime(registration.startTime),
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
                if (hasPauseResume) ...[
                  Expanded(
                    child: _buildTimeChip(
                      theme,
                      registration.pauseTime != null
                          ? DateTimeUtils.formatTime(registration.pauseTime!)
                          : '--:--',
                      Icons.pause_circle_outline,
                      theme.colorScheme.primary,
                      registration.pauseTime,
                      registration.shiftId,
                      'pause',
                      warningThreshold,
                      redThreshold,
                      forceWarning: isUnexpectedPause,
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
                      registration.resumeTime != null
                          ? DateTimeUtils.formatTime(registration.resumeTime!)
                          : '--:--',
                      Icons.play_circle_outline,
                      theme.colorScheme.primary,
                      registration.resumeTime,
                      registration.shiftId,
                      'resume',
                      warningThreshold,
                      redThreshold,
                      forceWarning: isUnexpectedPause,
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
                        ? DateTimeUtils.formatTime(registration.endTime!)
                        : 'En curso',
                    Icons.logout,
                    theme.colorScheme.primary,
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
        ],
      ),
    );
  }

  /// Builds a time display chip with compliance color indicators.
  ///
  /// Shows actual time with expected time in parentheses. Border color
  /// indicates compliance: no border (within threshold), orange (warning),
  /// or red (significant deviation).
  ///
  /// If [forceWarning] is true, the chip will always show warning color
  /// (used for unexpected pause/resume in continuous shifts).
  Widget _buildTimeChip(
    ThemeData theme,
    String time,
    IconData icon,
    Color iconColor,
    DateTime? actualTime,
    String shiftId,
    String timeType,
    int warningThreshold,
    int redThreshold, {
    bool forceWarning = false,
  }) {
    // Calculate time compliance indicator and get expected time
    Color? indicatorColor;
    String? expectedTimeStr;

    // If forceWarning is true and there's actual time, always show warning color
    if (forceWarning && actualTime != null) {
      indicatorColor = ColorUtils.parseHexColor(_currentTheme.colorOrange);
      // No expected time for unexpected pause/resume
      expectedTimeStr = null;
    } else {
      final shiftsState = ref.watch(
        employeeShiftsViewModelProvider(widget.employeeId),
      );
      final shiftTypesAsync = ref.watch(shiftTypesProvider);

      // First find the shift to get its shiftTypeId
      final shift = shiftsState.getShiftById(shiftId);

      if (shift == null) {
        return _buildSimpleTimeChip(theme, time, icon, iconColor);
      }

      final result = shiftTypesAsync.when(
        data: (types) {
          final shiftType = types
              .where((st) => st.id == shift.shiftTypeId)
              .firstOrNull;
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

          // If there's an actual time, calculate compliance color
          Color? color;
          if (actualTime != null) {
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

            // Calculate difference in minutes (rounded for UX consistency)
            final differenceMinutes = DateTimeUtils.differenceInMinutesRounded(
              expectedTime,
              actualTime,
            ).abs();

            // Determine color based on threshold
            if (differenceMinutes <= warningThreshold) {
              color = null; // No indicator needed, within acceptable range
            } else if (differenceMinutes < redThreshold) {
              color = ColorUtils.parseHexColor(_currentTheme.colorOrange);
            } else {
              color = ColorUtils.parseHexColor(_currentTheme.colorRed);
            }
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
          if (expectedTimeStr != null)
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

  /// Builds a simple time display chip without compliance indicators.
  ///
  /// Used when shift information is not available for comparison.
  Widget _buildSimpleTimeChip(
    ThemeData theme,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
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
        ],
      ),
    );
  }

  /// Returns the color corresponding to a registration status.
  ///
  /// Maps status to theme colors: green (compliant), orange (warning),
  /// red (non-compliant).
  Color _getColorFromStatus(TimeRegistrationStatus status) {
    // Returns the color based on the registration's global status.
    switch (status) {
      case TimeRegistrationStatus.green:
        return ColorUtils.parseHexColor(_currentTheme.colorGreen);
      case TimeRegistrationStatus.orange:
        return ColorUtils.parseHexColor(_currentTheme.colorOrange);
      case TimeRegistrationStatus.red:
        return ColorUtils.parseHexColor(_currentTheme.colorRed);
    }
  }

  /// Formats a date as a Spanish date string (e.g., '15 de Enero de 2025').
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

  /// Returns the Spanish month name with year (e.g., 'Enero 2025').
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

  /// Returns shift type information including name, color, and shift type object.
  ///
  /// Looks up the shift by ID, then retrieves its associated shift type.
  /// Returns default values if not found or still loading.
  Map<String, dynamic> _getShiftTypeInfo(String shiftId) {
    // Get employee shifts to find the shift and its shiftTypeId
    final shiftsState = ref.watch(
      employeeShiftsViewModelProvider(widget.employeeId),
    );
    final shiftTypesAsync = ref.watch(shiftTypesProvider);

    // First, find the shift by shiftId
    final shift = shiftsState.getShiftById(shiftId);

    if (shift == null) {
      return {
        'name': 'Turno',
        'color': ColorUtils.parseHexColor(_currentTheme.inactiveColor),
        'shiftType': null,
      };
    }

    // Now find the shift type using the shiftTypeId from the shift
    return shiftTypesAsync.when(
      data: (types) {
        final shiftType = types
            .where((st) => st.id == shift.shiftTypeId)
            .firstOrNull;
        return {
          'name': shiftType?.name ?? 'Turno',
          'color':
              shiftType?.color ??
              ColorUtils.parseHexColor(_currentTheme.inactiveColor),
          'shiftType': shiftType,
        };
      },
      loading: () => {
        'name': 'Turno',
        'color': ColorUtils.parseHexColor(_currentTheme.inactiveColor),
        'shiftType': null,
      },
      error: (_, _) => {
        'name': 'Turno',
        'color': ColorUtils.parseHexColor(_currentTheme.inactiveColor),
        'shiftType': null,
      },
    );
  }
}
