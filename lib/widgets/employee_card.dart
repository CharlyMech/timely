import 'package:flutter/material.dart';
import 'package:timely/models/employee.dart';
import 'package:timely/widgets/time_registration_widget.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const EmployeeCard({super.key, required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.primaryColor,
                child: Text(
                  _getInitials(employee.fullName),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                employee.fullName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TimeRegistrationWidget(
                registration: employee.currentRegistration,
                size: 80,
                showDetails: false,
              ),
              const SizedBox(height: 8),
              _buildStatusChip(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final registration = employee.currentRegistration;

    if (registration == null) {
      return Chip(
        label: const Text('Sin registro'),
        backgroundColor: theme.colorScheme.surface,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }

    if (registration.isActive) {
      return Chip(
        label: const Text('En jornada'),
        backgroundColor: const Color(0xFF46B56C).withValues(alpha: 0.2),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF46B56C),
          fontWeight: FontWeight.w600,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    } else {
      return Chip(
        label: const Text('Finalizada'),
        backgroundColor: theme.colorScheme.surface,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
