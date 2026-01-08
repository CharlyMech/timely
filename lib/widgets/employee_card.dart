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

class EmployeeCard extends ConsumerStatefulWidget {
  final Employee employee;
  final VoidCallback onTap;
  final double? height;
  final double padding;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
    this.height = double.infinity,
    this.padding = 16,
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
    if (oldWidget.employee.currentRegistration?.id != widget.employee.currentRegistration?.id ||
        oldWidget.employee.currentRegistration?.isActive != widget.employee.currentRegistration?.isActive) {
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
      child: Column(
        children: [
          SubtitleText(widget.employee.fullName),
          const SizedBox(height: 12),
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
      ),
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

    final totalMinutes = registration.totalMinutes;
    final targetMinutes = 420; // 7h
    final isActive = registration.isActive;
    final status = registration.status;

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

    // Get target time from config (default to 480 if not loaded)
    final configAsync = ref.watch(appConfigProvider);
    final targetTimeMinutes = configAsync.when(
      data: (config) => config.targetTimeMinutes,
      loading: () => 480,
      error: (_, _) => 480,
    );

    final remaining = registration.remainingMinutes(targetTimeMinutes);
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
}
