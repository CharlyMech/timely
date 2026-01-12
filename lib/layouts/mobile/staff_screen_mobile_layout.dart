import 'package:flutter/material.dart';
import 'package:timely/widgets/employee_card.dart';

class StaffScreenMobileLayout extends StatelessWidget {
  final List<dynamic> employees;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final Function(dynamic) onEmployeeTap;

  const StaffScreenMobileLayout({
    super.key,
    required this.employees,
    required this.scrollController,
    required this.onRefresh,
    required this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EmployeeCard(
              employee: employee,
              height: 130,
              onTap: () => onEmployeeTap(employee),
              layoutType: 'mobile',
            ),
          );
        },
      ),
    );
  }
}
