import 'package:flutter/material.dart';

class EmployeeProfileTabletLayout extends StatelessWidget {
  final Widget profileHeader;
  final Widget shiftsCalendar;

  const EmployeeProfileTabletLayout({
    super.key,
    required this.profileHeader,
    required this.shiftsCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileHeader,
          shiftsCalendar,
        ],
      ),
    );
  }
}
