import 'package:flutter/material.dart';

class EmployeeProfileMobileLayout extends StatelessWidget {
  final Widget profileHeader;
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
