import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/models/shift.dart';
import 'package:timely/viewmodels/employee_profile_viewmodel.dart';
import 'package:timely/config/providers.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/employee_avatar.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/color_utils.dart';
import 'package:timely/utils/responsive_utils.dart';
import 'package:timely/layouts/mobile/employee_profile_mobile_layout.dart';
import 'package:timely/layouts/tablet/employee_profile_tablet_layout.dart';

/// Screen that displays an employee's profile with their scheduled shifts calendar.
///
/// This screen shows employee information and a calendar view of their assigned shifts,
/// allowing users to view shift details and navigate to registration history.
/// It adapts its layout for mobile and tablet devices.
class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

/// State for [EmployeeProfileScreen] that manages calendar selection and data loading.
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
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
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
          spacing: responsive.spacing,
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

  /// Builds the main content layout using responsive mobile or tablet layout.
  ///
  /// Displays employee profile header and shifts calendar in a layout
  /// appropriate for the current device screen size.
  Widget _buildContent(ThemeData theme, EmployeeProfileState state) {
    final responsive = context.responsive;

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
        await ref
            .read(employeeProfileViewModelProvider(widget.employeeId).notifier)
            .loadCalendarShifts(_focusedDay);
      },
      child: responsive.isMobile
          ? EmployeeProfileMobileLayout(
              profileHeader: _buildProfileHeader(theme, employee),
              shiftsCalendar: _buildShiftsCalendar(theme, state),
            )
          : EmployeeProfileTabletLayout(
              profileHeader: _buildProfileHeader(theme, employee),
              shiftsCalendar: _buildShiftsCalendar(theme, state),
            ),
    );
  }

  /// Builds the profile header section with employee avatar and information.
  ///
  /// Creates a responsive layout showing the employee's avatar, name, role,
  /// and ID, along with a button to navigate to their registration history.
  /// The layout adapts between mobile (vertical) and tablet (horizontal).
  Widget _buildProfileHeader(ThemeData theme, employee) {
    final responsive = context.responsive;

    // Responsiveness parameters
    final avatarRadius = responsive.responsiveValue(
      mobile: 40.0,
      tablet: 56.0,
      desktop: 64.0,
    );

    final iconSize = responsive.responsiveValue(
      mobile: 32.0,
      tablet: 40.0,
      desktop: 44.0,
    );

    if (responsive.isMobile) {
      return Column(
        spacing: responsive.spacing,
        children: [
          // Mobile
          CustomCard(
            child: Row(
              spacing: responsive.spacing,
              children: [
                EmployeeAvatar(
                  fullName: employee.fullName,
                  imageUrl: employee.avatarUrl,
                  radius: avatarRadius,
                  useResponsiveSize: false,
                ),
                Expanded(
                  child: Column(
                    spacing: responsive.spacing * 0.3,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rol: ${_getRoleName(employee.roleId)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        'ID: ${employee.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
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
          // Mobile - full width
          CustomCard(
            onTap: () {
              context.push(
                '/employee/${widget.employeeId}/registrations',
                extra: {'employeeName': employee.fullName},
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: responsive.spacing,
              children: [
                Icon(
                  Icons.history,
                  size: iconSize,
                  color: theme.colorScheme.primary,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'Historial',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Ver registros',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        spacing: responsive.spacing,
        children: [
          Expanded(
            flex: 3,
            child: CustomCard(
              child: Row(
                spacing: responsive.spacing,
                children: [
                  EmployeeAvatar(
                    fullName: employee.fullName,
                    imageUrl: employee.avatarUrl,
                    radius: avatarRadius,
                    useResponsiveSize: false,
                  ),
                  Expanded(
                    child: Column(
                      spacing: responsive.spacing * 0.5,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Rol: ${_getRoleName(employee.roleId)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        Text(
                          'ID: ${employee.id}',
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
              onTap: () {
                context.push(
                  '/employee/${widget.employeeId}/registrations',
                  extra: {'employeeName': employee.fullName},
                );
              },
              child: Column(
                spacing: responsive.spacing * 0.4,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: iconSize,
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the interactive shift calendar widget.
  ///
  /// Displays a month/week calendar view showing the employee's assigned shifts
  /// with color coding by shift type. Users can select days to view shift details
  /// and switch between month and week views.
  Widget _buildShiftsCalendar(ThemeData theme, EmployeeProfileState state) {
    // Create a map of dates to shifts for quick lookup
    final shiftsByDate = <DateTime, Shift>{};
    for (var shift in state.calendarShifts) {
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
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
                    color: Colors.transparent,
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
                      final shiftColor = _getShiftTypeColorById(
                        shift.shiftTypeId,
                      );

                      final margin = _calendarFormat == CalendarFormat.week
                          ? 5.0
                          : 4.0;
                      final borderWidth = _calendarFormat == CalendarFormat.week
                          ? 2.0
                          : 1.8;

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
                      final isSelected = DateTimeUtils.isSameDay(
                        _selectedDay,
                        date,
                      );
                      final shiftColor = _getShiftTypeColorById(
                        shift.shiftTypeId,
                      );

                      final margin = _calendarFormat == CalendarFormat.week
                          ? 5.0
                          : 4.0;
                      final borderWidth = _calendarFormat == CalendarFormat.week
                          ? 2.0
                          : 1.8;

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
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.4,
                            ),
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
                  // Load shifts for the new month/week range
                  ref
                      .read(
                        employeeProfileViewModelProvider(
                          widget.employeeId,
                        ).notifier,
                      )
                      .loadCalendarShifts(focusedDay);
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

  /// Builds the shift type legend info button.
  ///
  /// Creates an info icon that when tapped displays a dialog explaining
  /// all available shift types, their colors, durations, and schedules.
  Widget _buildShiftTypeLegendTooltip(ThemeData theme) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (shiftTypes) {
        return GestureDetector(
          onTap: () {
            _showShiftTypesOverlay(context, theme, shiftTypes);
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

  /// Shows a dialog overlay with detailed shift type information.
  ///
  /// Displays all shift types with their colors, names, durations, and schedules
  /// in a modal dialog for user reference.
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
                              Row(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    shiftType.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '(${DateTimeUtils.minutesToReadable(shiftType.targetTimeMinutes)})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
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

  /// Builds a detailed card showing information for the selected shift.
  ///
  /// Displays the shift date, type, target hours, and scheduled times
  /// (start, pause, resume, end) in a responsive layout that adapts
  /// to mobile and tablet screen sizes.
  Widget _buildSelectedShiftCard(ThemeData theme, Shift shift) {
    final shiftColor = _getShiftTypeColorById(shift.shiftTypeId);
    final pauseTime = _getShiftPauseTime(shift.shiftTypeId);
    final resumeTime = _getShiftResumeTime(shift.shiftTypeId);
    final hasPause = pauseTime != null && resumeTime != null;
    final targetHours = _getTargetHours();
    final responsive = context.responsive;

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

          // Responsive layout: 2 rows on mobile, with pause; 1 row on tablet with pause
          if (responsive.isMobile && hasPause) ...[
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
                    _getShiftStartTime(shift.shiftTypeId),
                    Icons.login,
                    theme.colorScheme.primary,
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
                    pauseTime,
                    Icons.pause_circle_outline,
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
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
                    resumeTime,
                    Icons.play_circle_outline,
                    theme.colorScheme.primary,
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
                    _getShiftEndTime(shift.shiftTypeId),
                    Icons.logout,
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ] else ...[
            // No pause layout
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
                if (hasPause) ...[
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
                    _getShiftStartTime(shift.shiftTypeId),
                    Icons.login,
                    theme.colorScheme.primary,
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
                      theme.colorScheme.primary,
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
                      theme.colorScheme.primary,
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
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a time display chip with an icon.
  ///
  /// Creates a styled container showing a time value with an associated icon,
  /// used to display shift schedule times in a consistent format.
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

  /// Returns the formatted target hours string from app configuration.
  ///
  /// Converts the default target time in minutes to a human-readable
  /// format (e.g., '8h', '7h 30m'). Returns '--h' if loading or on error.
  String _getTargetHours() {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      data: (config) {
        final hours = config.defaultTargetTimeMinutes ~/ 60;
        final minutes = config.defaultTargetTimeMinutes % 60;
        if (minutes == 0) {
          return '${hours}h';
        }
        return '${hours}h ${minutes}m';
      },
      loading: () => '--h',
      error: (_, _) => '--h',
    );
  }

  /// Returns the display name for a role by its ID.
  ///
  /// Looks up the role in the roles provider and returns its display name.
  /// Falls back to the role ID itself if not found or still loading.
  String _getRoleName(String roleId) {
    final rolesAsync = ref.watch(rolesProvider);
    return rolesAsync.when(
      data: (roles) {
        try {
          final role = roles.firstWhere((r) => r.id == roleId);
          return role.displayName;
        } catch (e) {
          return roleId;
        }
      },
      loading: () => 'Cargando...',
      error: (_, _) => roleId,
    );
  }

  /// Returns the name of a shift type by its ID.
  ///
  /// Looks up the shift type and returns its name. Falls back to the
  /// shift type ID if not found or still loading.
  String _getShiftTypeName(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.name;
        } catch (e) {
          return shiftTypeId;
        }
      },
      loading: () => shiftTypeId,
      error: (_, _) => shiftTypeId,
    );
  }

  /// Returns the color associated with a shift type by its ID.
  ///
  /// Looks up the shift type and returns its configured color.
  /// Defaults to grey if not found or still loading.
  Color _getShiftTypeColorById(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.color;
        } catch (e) {
          return ColorUtils.greyColor;
        }
      },
      loading: () => ColorUtils.greyColor,
      error: (_, _) => ColorUtils.greyColor,
    );
  }

  /// Returns the start time for a shift type by its ID.
  ///
  /// Looks up and returns the configured start time (e.g., '09:00').
  /// Returns '--:--' if not found or still loading.
  String _getShiftStartTime(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.startTime;
        } catch (e) {
          return '--:--';
        }
      },
      loading: () => '--:--',
      error: (_, _) => '--:--',
    );
  }

  /// Returns the end time for a shift type by its ID.
  ///
  /// Looks up and returns the configured end time (e.g., '17:00').
  /// Returns '--:--' if not found or still loading.
  String _getShiftEndTime(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.endTime;
        } catch (e) {
          return '--:--';
        }
      },
      loading: () => '--:--',
      error: (_, _) => '--:--',
    );
  }

  /// Returns the pause time for a shift type by its ID, if configured.
  ///
  /// Returns null if the shift type doesn't have a pause configured,
  /// or if not found/still loading.
  String? _getShiftPauseTime(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.pauseTime;
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }

  /// Returns the resume time for a shift type by its ID, if configured.
  ///
  /// Returns null if the shift type doesn't have a resume time configured,
  /// or if not found/still loading.
  String? _getShiftResumeTime(String shiftTypeId) {
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    return shiftTypesAsync.when(
      data: (types) {
        try {
          final shiftType = types.firstWhere((st) => st.id == shiftTypeId);
          return shiftType.resumeTime;
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }

  /// Builds the calendar view mode toggle between week and month views.
  ///
  /// Creates a segmented control allowing users to switch between
  /// weekly and monthly calendar displays.
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

  /// Builds an individual view mode button for the calendar format selector.
  ///
  /// Creates a clickable icon button that toggles the calendar format
  /// with visual feedback when selected.
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
