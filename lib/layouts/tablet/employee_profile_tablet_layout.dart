import 'package:flutter/material.dart';

/// Tablet-optimized layout for employee profile screen.
///
/// Provides a vertical scrollable layout with larger padding and spacing
/// compared to mobile, taking advantage of the additional screen real estate
/// available on tablet devices.
class EmployeeProfileTabletLayout extends StatelessWidget {
  /// Widget containing employee information and avatar.
  final Widget profileHeader;

  /// Widget displaying the employee's shift calendar.
  final Widget shiftsCalendar;

  const EmployeeProfileTabletLayout({
    super.key,
    required this.profileHeader,
    required this.shiftsCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileHeader,
                  shiftsCalendar,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
