import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';
import 'package:timely/widgets/employee_avatar.dart';
import 'package:timely/widgets/time_gauge.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/config/providers.dart';

/// Card widget displaying employee information and time registration status.
///
/// Shows employee avatar, name, time gauge progress, and remaining/exceeded time.
/// Updates every second for active registrations. Supports mobile and tablet layouts.
class EmployeeCard extends ConsumerStatefulWidget {
  final Employee employee;
  final VoidCallback onTap;
  final double? height;
  final double padding;
  final String layoutType;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
    this.height = double.infinity,
    this.padding = 16,
    this.layoutType = 'mobile',
  });

  @override
  ConsumerState<EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends ConsumerState<EmployeeCard> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(EmployeeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if registration changed
    if (oldWidget.employee.currentRegistration?.id !=
            widget.employee.currentRegistration?.id ||
        oldWidget.employee.currentRegistration?.isActive !=
            widget.employee.currentRegistration?.isActive) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _updateTimer?.cancel();
    // Only start timer if there's an active registration
    if (widget.employee.currentRegistration?.isActive == true) {
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild of only this widget
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeData = ref
        .read(themeViewModelProvider.notifier)
        .getThemeData(brightness);

    // Get current theme
    final themeState = ref.watch(themeViewModelProvider);
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    final myTheme = themes[currentThemeType]!;

    return CustomCard(
      height: widget.height,
      padding: widget.padding,
      onTap: widget.onTap,
      borderRadius: 12,
      elevation: 1,
      child: widget.layoutType == 'mobile'
          ? _buildMobileLayout(themeData, myTheme)
          : _buildTabletLayout(themeData, myTheme),
    );
  }

  Widget _buildRemainingTimeLabel(ThemeData theme, MyTheme myTheme) {
    final registration = widget.employee.currentRegistration;

    if (registration == null) {
      return Text(
        'Sin registro de entrada',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
      );
    }

    // Obtener configuración y shift types
    final configAsync = ref.watch(appConfigProvider);
    final shiftTypesAsync = ref.watch(shiftTypesProvider);

    // Get target time from employee's shift type if available
    final shiftType = shiftTypesAsync.when(
      data: (types) {
        final todayShift = widget.employee.todayShift;
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

    final int targetMinutes = shiftType?.targetTimeMinutes ??
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
    final isActive = registration.isActive;
    final status = registration.getStatus(
      targetMinutes: targetMinutes,
      warningThreshold: warningThreshold,
      redThreshold: redThreshold,
    );

    if (totalMinutes > targetMinutes) {
      final exceeded = totalMinutes - targetMinutes;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tiempo excedido: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '+${DateTimeUtils.minutesToReadable(exceeded)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getColorFromTheme(status, myTheme),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    if (!isActive) {
      final remaining = targetMinutes - totalMinutes;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tiempo restante: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '-${DateTimeUtils.minutesToReadable(remaining)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getColorFromTheme(status, myTheme),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    final remaining = registration.remainingMinutes(targetMinutes);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Restante: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          DateTimeUtils.minutesToReadable(remaining),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getColorFromTheme(TimeRegistrationStatus.green, myTheme),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Color _getColorFromTheme(TimeRegistrationStatus status, MyTheme myTheme) {
    switch (status) {
      case TimeRegistrationStatus.green:
        return Color(int.parse(myTheme.colorGreen.replaceFirst('#', '0xff')));
      case TimeRegistrationStatus.orange:
        return Color(int.parse(myTheme.colorOrange.replaceFirst('#', '0xff')));
      case TimeRegistrationStatus.red:
        return Color(int.parse(myTheme.colorRed.replaceFirst('#', '0xff')));
    }
  }

  Widget _buildMobileLayout(ThemeData themeData, MyTheme myTheme) {
    return Row(
      spacing: 16,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            TimeGauge(
              size: 100,
              strokeWidth: 18,
              registration: widget.employee.currentRegistration,
              mode: GaugeMode.none,
              myTheme: myTheme,
            ),
            EmployeeAvatar(
              fullName: widget.employee.fullName,
              imageUrl: widget.employee.avatarUrl,
              radius: 32,
            ),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              SubtitleText(
                widget.employee.fullName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              _buildRemainingTimeLabel(themeData, myTheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData themeData, MyTheme myTheme) {
    return Column(
      spacing: 12,
      children: [
        SubtitleText(widget.employee.fullName),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              TimeGauge(
                size: 170,
                registration: widget.employee.currentRegistration,
                mode: GaugeMode.none,
                myTheme: myTheme,
              ),
              EmployeeAvatar(
                fullName: widget.employee.fullName,
                imageUrl: widget.employee.avatarUrl,
                radius: 60,
              ),
            ],
          ),
        ),
        _buildRemainingTimeLabel(themeData, myTheme),
      ],
    );
  }
}
