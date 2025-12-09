import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/widgets/custom_text.dart';
import 'package:timely/widgets/employee_avatar.dart';
import 'package:timely/widgets/time_gauge.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/constants/themes.dart';

class EmployeeCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SizedBox(
      height: height,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                SubtitleText(employee.fullName),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TimeGauge(
                        size: 170,
                        registration: employee.currentRegistration,
                        mode: GaugeMode.none,
                        myTheme: myTheme,
                      ),
                      EmployeeAvatar(
                        fullName: employee.fullName,
                        imageUrl: employee.avatarUrl,
                        radius: 60,
                      ),
                    ],
                  ),
                ),
                _buildRemainingTimeLabel(themeData, myTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingTimeLabel(ThemeData theme, MyTheme myTheme) {
    final registration = employee.currentRegistration;

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

    final remaining = registration.remainingMinutes;
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
