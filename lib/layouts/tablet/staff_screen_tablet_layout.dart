import 'package:flutter/material.dart';
import 'package:timely/widgets/employee_card.dart';

class StaffScreenTabletLayout extends StatelessWidget {
  final List<dynamic> employees;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
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
