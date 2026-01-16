import 'package:flutter/material.dart';

/// Mobile-optimized layout for employee registrations history screen.
///
/// Displays registration data in a vertical scrollable layout with monthly
/// summary information, calendar view, and details for the selected day.
/// Uses mobile-specific padding and spacing for smaller screens.
class EmployeeRegistrationsMobileLayout extends StatelessWidget {
  /// Widget showing the count of registrations for the current month.
  final Widget monthlyCountInfo;

  /// Widget displaying the calendar with registration indicators.
  final Widget calendar;

  /// Optional widget showing details for the currently selected day.
  final Widget? selectedDayContent;

  const EmployeeRegistrationsMobileLayout({
    super.key,
    required this.monthlyCountInfo,
    required this.calendar,
    this.selectedDayContent,
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
                children: [
                  monthlyCountInfo,
                  calendar,
                  if (selectedDayContent != null) selectedDayContent!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
