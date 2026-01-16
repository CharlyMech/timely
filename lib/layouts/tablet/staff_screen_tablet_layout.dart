import 'package:flutter/material.dart';
import 'package:timely/widgets/employee_card.dart';

/// Tablet-optimized layout for staff listing screen.
///
/// Displays employees in a responsive grid that adapts to device orientation:
/// - Portrait: 2 columns
/// - Landscape: 3 columns
///
/// Includes pull-to-refresh functionality and larger padding to optimize
/// for tablet screen sizes.
class StaffScreenTabletLayout extends StatelessWidget {
  /// List of employee objects to display.
  final List<dynamic> employees;

  /// Controller for programmatic scroll management.
  final ScrollController scrollController;

  /// Callback invoked when user pulls down to refresh.
  final VoidCallback onRefresh;

  /// Callback invoked when user taps an employee card.
  final Function(dynamic) onEmployeeTap;

  const StaffScreenTabletLayout({
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              final crossAxisCount = isLandscape ? 3 : 2;
              const spacing = 16.0;

              return GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1.3,
                ),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  return EmployeeCard(
                    employee: employee,
                    onTap: () => onEmployeeTap(employee),
                    layoutType: 'tablet',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
