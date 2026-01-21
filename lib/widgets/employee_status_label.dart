import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/config/providers.dart';
import 'package:timely/models/employee_status.dart';

/// A label widget that displays the employee's current status.
///
/// Shows the status display name with appropriate colors based on the
/// status configuration. Uses colorContainer as background and color
/// for text/border styling.
class EmployeeStatusLabel extends ConsumerWidget {
  /// The status ID (UUID) to display.
  final String statusId;

  /// Optional padding override for the label.
  final EdgeInsetsGeometry? padding;

  /// Optional font size for the label text.
  final double? fontSize;

  const EmployeeStatusLabel({
    super.key,
    required this.statusId,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(employeeStatusesProvider);

    return statusesAsync.when(
      data: (statuses) {
        final status = _findStatusById(statuses, statusId);
        if (status == null) {
          return const SizedBox.shrink();
        }
        return _buildStatusLabel(context, status);
      },
      loading: () => _buildLoadingLabel(context),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Finds the [EmployeeStatus] by its ID.
  EmployeeStatus? _findStatusById(List<EmployeeStatus> statuses, String id) {
    try {
      return statuses.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Builds the status label widget with colors from the status configuration.
  Widget _buildStatusLabel(BuildContext context, EmployeeStatus status) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.colorContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? theme.textTheme.labelSmall?.fontSize,
        ),
      ),
    );
  }

  /// Builds a placeholder label while loading.
  Widget _buildLoadingLabel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '...',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? theme.textTheme.labelSmall?.fontSize,
        ),
      ),
    );
  }
}
