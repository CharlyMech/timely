import 'package:flutter/material.dart';

class EmployeeRegistrationsMobileLayout extends StatelessWidget {
  final Widget monthlyCountInfo;
  final Widget calendar;
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
