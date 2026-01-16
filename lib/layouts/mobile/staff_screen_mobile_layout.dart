import 'package:flutter/material.dart';
import 'package:timely/widgets/employee_card.dart';

/// Mobile-optimized layout for staff listing screen.
///
/// Displays employees in a vertical scrollable list with pull-to-refresh
/// functionality. Each employee is shown in a card optimized for mobile
/// viewing with appropriate height and spacing for touch interaction.
class StaffScreenMobileLayout extends StatelessWidget {
  /// List of employee objects to display.
  final List<dynamic> employees;

  /// Controller for programmatic scroll management.
  final ScrollController scrollController;

  /// Callback invoked when user pulls down to refresh.
  final VoidCallback onRefresh;

  /// Callback invoked when user taps an employee card.
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
