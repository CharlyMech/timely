import 'package:flutter/material.dart';

class EmployeeRegistrationsTabletLayout extends StatelessWidget {
  final Widget monthlyCountInfo;
  final Widget calendar;
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
