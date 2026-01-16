import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/utils/color_utils.dart';
import 'package:timely/utils/responsive_utils.dart';
import 'package:timely/viewmodels/employee_detail_viewmodel.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';
import 'package:timely/widgets/employee_detail_appbar.dart';
import 'package:timely/widgets/pin_verification_dialog.dart';
import 'package:timely/widgets/time_gauge.dart';
import 'package:timely/layouts/mobile/time_registration_detail_mobile_layout.dart';
import 'package:timely/layouts/tablet/time_registration_detail_tablet_layout.dart';

/// Screen that displays detailed time registration information for an employee.
///
/// This screen shows the current work session with a time gauge, shift details,
/// and action buttons for starting, pausing, resuming, or ending the workday.
/// It adapts its layout for mobile and tablet devices.
class TimeRegistrationDetailScreen extends ConsumerStatefulWidget {
  /// The unique identifier of the employee whose registration details to display.
  final String employeeId;

  const TimeRegistrationDetailScreen({super.key, required this.employeeId});

  @override
  ConsumerState<TimeRegistrationDetailScreen> createState() =>
      _TimeRegistrationDetailScreenState();
}

/// State for [TimeRegistrationDetailScreen] that manages employee data loading and UI state.
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
        onAvatarTap: detailState.employee != null
            ? () =>
                  _showPinVerificationForProfile(context, detailState.employee!)
            : null,
      ),
      body: detailState.isLoading
          ? _buildLoadingState(theme)
          : detailState.error != null
          ? _buildErrorState(theme, detailState.error!)
          : _buildDetailContent(context, theme, detailState),
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

  /// Builds the error state widget with error message and retry button.
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
            SizedBox(height: responsive.spacing * 1.5),
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

  /// Builds the main content layout with time gauge and action buttons.
  ///
  /// Displays a circular time gauge showing current work session progress,
  /// contextual action buttons based on registration state (start, pause,
  /// resume, end), and shift schedule information. Uses responsive layouts
  /// for mobile and tablet devices.
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

    final responsive = context.responsive;

    // Build gauge widget with responsive sizes
    final gaugeSize = responsive.isMobile ? 280.0 : 350.0;
    final strokeWidth = responsive.isMobile ? 35.0 : 40.0;

    final gaugeWidget = TimeGauge(
      registration: registration,
      size: gaugeSize,
      strokeWidth: strokeWidth,
      mode: GaugeMode.time,
      myTheme: myTheme,
    );

    // Determine action buttons widget
    Widget actionButtons;
    if (registration == null) {
      // Check if employee has a shift assigned for today
      if (employee.todayShift == null) {
        actionButtons = _buildNoShiftMessage(theme);
      } else {
        actionButtons = _buildStartButton(context, theme);
      }
    } else if (hasActiveRegistration) {
      actionButtons = _buildActiveButtons(
        context,
        theme,
        myTheme,
        registration,
      );
    } else {
      actionButtons = _buildCompletedMessage(theme, registration, myTheme);
    }

    // Determine shift info widget (shows expected times from shift type and registration details if exists)
    Widget? shiftInfoWidget;
    if (employee.todayShift != null) {
      shiftInfoWidget = _buildShiftInfo(
        theme,
        employee.todayShift!.shiftTypeId,
        registration,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
            .refresh();
      },
      child: responsive.isMobile
          ? TimeRegistrationDetailMobileLayout(
              gaugeWidget: gaugeWidget,
              actionButtons: actionButtons,
              shiftInfo: shiftInfoWidget,
              registrationDetails: null,
            )
          : TimeRegistrationDetailTabletLayout(
              gaugeWidget: gaugeWidget,
              actionButtons: actionButtons,
              shiftInfo: shiftInfoWidget,
              registrationDetails: null,
            ),
    );
  }

  /// Builds the shift information card showing expected and actual times.
  ///
  /// Displays the shift type, target hours, and scheduled times (start,
  /// pause, resume, end). If a registration exists, also shows actual
  /// recorded times with compliance indicators comparing them to expected times.
  Widget _buildShiftInfo(
    ThemeData theme,
    String shiftTypeId,
    TimeRegistration? registration,
  ) {
    final responsive = context.responsive;
    final shiftTypesAsync = ref.watch(shiftTypesProvider);
    final configAsync = ref.watch(appConfigProvider);

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

    return shiftTypesAsync.when(
      data: (types) {
        final shiftType = types.where((st) => st.id == shiftTypeId).firstOrNull;
        if (shiftType == null) return const SizedBox.shrink();

        final hasPause = shiftType.hasPauseResume;
        final shiftColor = shiftType.color;
        final targetMinutes = shiftType.targetTimeMinutes;

        final hours = targetMinutes ~/ 60;
        final minutes = targetMinutes % 60;
        final targetHours = minutes == 0
            ? '${hours}h'
            : '${hours}h ${minutes}m';

        return CustomCard(
          width: double.infinity,
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with shift type name and target hours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.work_outline, color: shiftColor, size: 20),
                      Text(
                        shiftType.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: shiftColor,
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
                    child: Text(
                      targetHours,
                      style: TextStyle(
                        color: shiftColor,
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

              // Layout responsive: mobile -> 2 rows with pause, tablet -> 1 row
              if (responsive.isMobile && hasPause) ...[
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        'Entrada',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.startTime,
                        Icons.login,
                        shiftColor,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.pauseTime!,
                        Icons.pause_circle_outline,
                        shiftColor,
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Salida',
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
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.resumeTime!,
                        Icons.play_circle_outline,
                        shiftColor,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.endTime,
                        Icons.logout,
                        shiftColor,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // No pause layout for mobile and tablet
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: Text(
                        'Entrada',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
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
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        'Salida',
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
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.startTime,
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
                        child: _buildExpectedTimeChip(
                          theme,
                          shiftType.pauseTime!,
                          Icons.pause_circle_outline,
                          shiftColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      Expanded(
                        child: _buildExpectedTimeChip(
                          theme,
                          shiftType.resumeTime!,
                          Icons.play_circle_outline,
                          shiftColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                    Expanded(
                      child: _buildExpectedTimeChip(
                        theme,
                        shiftType.endTime,
                        Icons.logout,
                        shiftColor,
                      ),
                    ),
                  ],
                ),
              ],

              // Add active registration chips
              if (registration != null) ...[
                // Divider
                Container(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),

                // Responsive layout for time registration chips
                if (responsive.isMobile && hasPause) ...[
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
                          shiftType.startTime,
                          warningThreshold,
                          redThreshold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      Expanded(
                        child: _buildTimeChip(
                          theme,
                          registration.pauseTime != null
                              ? DateTimeUtils.formatTime(
                                  registration.pauseTime!,
                                )
                              : '--:--',
                          Icons.pause_circle_outline,
                          theme.colorScheme.primary,
                          registration.pauseTime,
                          shiftType.pauseTime,
                          warningThreshold,
                          redThreshold,
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
                              ? DateTimeUtils.formatTime(
                                  registration.resumeTime!,
                                )
                              : '--:--',
                          Icons.play_circle_outline,
                          theme.colorScheme.primary,
                          registration.resumeTime,
                          shiftType.resumeTime,
                          warningThreshold,
                          redThreshold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
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
                          shiftType.endTime,
                          warningThreshold,
                          redThreshold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Layout horizontal para tablet o mobile sin pausa
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: _buildTimeChip(
                          theme,
                          DateTimeUtils.formatTime(registration.startTime),
                          Icons.login,
                          theme.colorScheme.primary,
                          registration.startTime,
                          shiftType.startTime,
                          warningThreshold,
                          redThreshold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      if (hasPause) ...[
                        Expanded(
                          child: _buildTimeChip(
                            theme,
                            registration.pauseTime != null
                                ? DateTimeUtils.formatTime(
                                    registration.pauseTime!,
                                  )
                                : '--:--',
                            Icons.pause_circle_outline,
                            theme.colorScheme.primary,
                            registration.pauseTime,
                            shiftType.pauseTime,
                            warningThreshold,
                            redThreshold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        Expanded(
                          child: _buildTimeChip(
                            theme,
                            registration.resumeTime != null
                                ? DateTimeUtils.formatTime(
                                    registration.resumeTime!,
                                  )
                                : '--:--',
                            Icons.play_circle_outline,
                            theme.colorScheme.primary,
                            registration.resumeTime,
                            shiftType.resumeTime,
                            warningThreshold,
                            redThreshold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
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
                          shiftType.endTime,
                          warningThreshold,
                          redThreshold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Builds a time chip displaying expected shift time with an icon.
  ///
  /// Shows the scheduled time in the shift type's color, used to display
  /// expected start, pause, resume, and end times.
  Widget _buildExpectedTimeChip(
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

  /// Shows a PIN verification dialog for accessing employee profile.
  ///
  /// Prompts the user to enter the employee's PIN. On successful verification,
  /// navigates to the employee's profile screen.
  Future<void> _showPinVerificationForProfile(
    BuildContext context,
    employee,
  ) async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PinVerificationDialog(
        correctPin: employee.pin,
        employeeName: employee.fullName,
      ),
    );

    if (verified == true && mounted && context.mounted) {
      context.push('/employee/${employee.id}/profile');
    }
  }

  /// Builds a time chip with compliance color indicators.
  ///
  /// Displays actual recorded time and compares it to expected time.
  /// Border color indicates compliance level: no border (within threshold),
  /// orange (warning), or red (significant deviation).
  Widget _buildTimeChip(
    ThemeData theme,
    String time,
    IconData icon,
    Color iconColor,
    DateTime? actualTime,
    String? expectedTime,
    int warningThreshold,
    int redThreshold,
  ) {
    // Calculate time compliance indicator
    Color? indicatorColor;
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeState = ref.watch(themeViewModelProvider);
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    final myTheme = themes[currentThemeType]!;

    if (actualTime != null && expectedTime != null) {
      // Parse expected time and compare with actual
      final timeParts = expectedTime.split(':');
      final expectedHour = int.parse(timeParts[0]);
      final expectedMinute = int.parse(timeParts[1]);

      // Create DateTime with same date but expected time
      final expectedDateTime = DateTime(
        actualTime.year,
        actualTime.month,
        actualTime.day,
        expectedHour,
        expectedMinute,
      );

      // Calculate difference in minutes (rounded for UX consistency)
      final differenceMinutes = DateTimeUtils.differenceInMinutesRounded(
        expectedDateTime,
        actualTime,
      ).abs();

      // Determine color based on threshold
      if (differenceMinutes <= warningThreshold) {
        indicatorColor = null; // No indicator needed, within acceptable range
      } else if (differenceMinutes < redThreshold) {
        indicatorColor = Color(
          int.parse(myTheme.colorOrange.replaceFirst('#', '0xff')),
        ); // Warning threshold exceeded
      } else {
        indicatorColor = Color(
          int.parse(myTheme.colorRed.replaceFirst('#', '0xff')),
        ); // Red threshold exceeded
      }
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
        ],
      ),
    );
  }

  /// Builds a message widget informing that no shift is assigned for today.
  ///
  /// Displayed when the employee doesn't have a shift scheduled for the
  /// current day and therefore cannot start a workday.
  Widget _buildNoShiftMessage(ThemeData theme) {
    return CustomCard(
      width: double.infinity,
      padding: 24,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SubtitleText(
            'No tienes un turno asignado para hoy',
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Contacta con tu supervisor para que te asigne un turno',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the start workday button widget.
  ///
  /// Displayed when no active registration exists and employee has an
  /// assigned shift for today. Tapping initiates the workday.
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
          Icon(Icons.play_arrow, size: 28, color: theme.colorScheme.onPrimary),
          SubtitleText('Comenzar jornada', color: theme.colorScheme.onPrimary),
        ],
      ),
    );
  }

  /// Builds action buttons for an active workday.
  ///
  /// Displays contextual buttons based on current registration state:
  /// - If paused: shows resume button
  /// - If active: shows pause button (if shift has pause) and end button
  /// - Layout adapts to mobile (vertical) and tablet (horizontal)
  Widget _buildActiveButtons(
    BuildContext context,
    ThemeData theme,
    MyTheme myTheme,
    TimeRegistration registration,
  ) {
    final detailState = ref.watch(
      employeeDetailViewModelProvider(widget.employeeId),
    );
    final shiftTypesAsync = ref.watch(shiftTypesProvider);

    // Check if shift type has pause/resume configured
    final shiftType = shiftTypesAsync.when(
      data: (types) {
        final todayShift = detailState.employee?.todayShift;
        if (todayShift != null) {
          try {
            return types.firstWhere((st) => st.id == todayShift.shiftTypeId);
          } catch (e) {
            return null;
          }
        }
        return null;
      },
      loading: () => null,
      error: (_, _) => null,
    );

    final hasPauseResume = shiftType?.hasPauseResume ?? false;
    final isPaused = registration.isPaused;
    final hasResumed =
        registration.pauseTime != null && registration.resumeTime != null;
    final responsive = context.responsive;

    // Determine which buttons to display based on the record status
    Widget? actionButton1; // Pause or Resume
    Widget? actionButton2; // End

    // Pause -> just show resume button
    if (isPaused) {
      actionButton1 = CustomCard(
        width: double.infinity,
        onTap: () => _resumeWorkday(context),
        padding: 24,
        color: theme.colorScheme.primary,
        child: Row(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow,
              size: 28,
              color: theme.colorScheme.onPrimary,
            ),
            SubtitleText(
              'Reanudar jornada',
              color: theme.colorScheme.onPrimary,
            ),
          ],
        ),
      );
    } else {
      // Not in pause mode: able to pause or end
      if (hasPauseResume && !hasResumed) {
        actionButton1 = CustomCard(
          width: double.infinity,
          onTap: () => _pauseWorkday(context),
          padding: 24,
          color: theme.colorScheme.secondary,
          child: Row(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pause, size: 28),
              SubtitleText('Pausar jornada'),
            ],
          ),
        );
      }

      actionButton2 = CustomCard(
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

    // Build device's layout
    final buttons = [
      if (actionButton1 != null) actionButton1,
      if (actionButton2 != null) actionButton2,
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    // Mobile: vertical layout
    if (responsive.isMobile) {
      return Column(spacing: 16, children: buttons);
    }

    // Tablet: horizontal layout
    if (buttons.length == 1) {
      return buttons.first;
    }

    return Row(
      spacing: 16,
      children: buttons.map((btn) => Expanded(child: btn)).toList(),
    );
  }

  /// Builds a message widget showing completed workday summary.
  ///
  /// Displays the completion status with an icon and color based on
  /// how well the actual time matches the target time (green for compliant,
  /// orange for warning, red for significant deviation).
  Widget _buildCompletedMessage(
    ThemeData theme,
    TimeRegistration registration,
    MyTheme myTheme,
  ) {
    final detailState = ref.watch(
      employeeDetailViewModelProvider(widget.employeeId),
    );

    // Get config and shift types
    final configAsync = ref.watch(appConfigProvider);
    final shiftTypesAsync = ref.watch(shiftTypesProvider);

    // Get shift type from employee's assigned shift
    final shiftType = shiftTypesAsync.when(
      data: (types) {
        final todayShift = detailState.employee?.todayShift;
        if (todayShift != null) {
          try {
            return types.firstWhere((st) => st.id == todayShift.shiftTypeId);
          } catch (e) {
            return null;
          }
        }
        return null;
      },
      loading: () => null,
      error: (_, _) => null,
    );

    // Use shift type targetTime if available, otherwise use default from config
    final int targetMinutes =
        shiftType?.targetTimeMinutes ??
        configAsync.when(
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

    final totalMinutes = registration.totalMinutes;
    final diffMinutes =
        targetMinutes -
        totalMinutes; // `-` means over time; `+` means under time

    final status = registration.getStatus(
      targetMinutes: targetMinutes,
      warningThreshold: warningThreshold,
      redThreshold: redThreshold,
    );
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

  /// Starts the workday for the employee.
  ///
  /// Creates a new time registration with the current timestamp as start time.
  /// Shows success or error feedback via snackbar.
  Future<void> _startDayOfWork(BuildContext context) async {
    try {
      await ref
          .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
          .startWorkday();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jornada iniciada correctamente'),
            backgroundColor: ColorUtils.greenColor,
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

  /// Pauses the current active workday.
  ///
  /// Records the pause time in the active registration. Shows success
  /// or error feedback via snackbar.
  Future<void> _pauseWorkday(BuildContext context) async {
    try {
      await ref
          .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
          .pauseWorkday();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jornada pausada correctamente'),
            backgroundColor: ColorUtils.greenColor,
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

  /// Resumes a paused workday.
  ///
  /// Records the resume time in the paused registration. Shows success
  /// or error feedback via snackbar.
  Future<void> _resumeWorkday(BuildContext context) async {
    try {
      await ref
          .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
          .resumeWorkday();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jornada reanudada correctamente'),
            backgroundColor: ColorUtils.greenColor,
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

  /// Shows a confirmation dialog before ending the workday.
  ///
  /// Warns the user that ending the workday cannot be reversed. If confirmed,
  /// records the end time and marks the registration as complete. Shows
  /// success or error feedback via snackbar.
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
              backgroundColor: ColorUtils.greenColor,
              showCloseIcon: true,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: ColorUtils.redColor,
              showCloseIcon: true,
            ),
          );
        }
      }
    }
  }
}
