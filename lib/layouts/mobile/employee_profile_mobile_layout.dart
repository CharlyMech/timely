import 'package:flutter/material.dart';

/// Mobile-optimized layout for employee profile screen.
///
/// Provides a vertical scrollable layout with the profile header at the top
/// and shifts calendar below. Uses mobile-specific padding and spacing for
/// optimal touch interaction on smaller screens.
class EmployeeProfileMobileLayout extends StatelessWidget {
  /// Widget containing employee information and avatar.
  final Widget profileHeader;

  /// Widget displaying the employee's shift calendar.
  final Widget shiftsCalendar;

  const EmployeeProfileMobileLayout({
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                spacing: 16,
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
