import 'package:flutter/material.dart';

/// Tablet-optimized layout for employee registrations history screen.
///
/// Displays registration data in a vertical scrollable layout with larger
/// spacing and padding optimized for tablet screens. Shows monthly summary,
/// calendar view, and details for the selected day.
class EmployeeRegistrationsTabletLayout extends StatelessWidget {
  /// Widget showing the count of registrations for the current month.
  final Widget monthlyCountInfo;

  /// Widget displaying the calendar with registration indicators.
  final Widget calendar;

  /// Optional widget showing details for the currently selected day.
  final Widget? selectedDayContent;

  const EmployeeRegistrationsTabletLayout({
    super.key,
    required this.monthlyCountInfo,
    required this.calendar,
    this.selectedDayContent,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        spacing: 24,
        children: [
          monthlyCountInfo,
          calendar,
          if (selectedDayContent != null) selectedDayContent!,
        ],
      ),
    );
  }
}
