import 'package:flutter/material.dart';

class EmployeeDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String employeeName;
  final String? employeeImageUrl;
  final VoidCallback? onBackPressed;

  const EmployeeDetailAppBar({
    super.key,
    required this.employeeName,
    this.employeeImageUrl,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 1,
      toolbarHeight: 80,
      backgroundColor: theme.appBarTheme.backgroundColor,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onSurface,
          size: 28,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        employeeName,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _buildAvatar(theme),
        ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (employeeImageUrl != null && employeeImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.surface,
        backgroundImage: NetworkImage(employeeImageUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Handle error silently, will show fallback icon
        },
        child: employeeImageUrl!.isEmpty
            ? Icon(
                Icons.person,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 28,
              )
            : null,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
      child: Icon(Icons.person, color: theme.primaryColor, size: 28),
    );
  }
}
