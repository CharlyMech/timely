import 'package:flutter/material.dart';
import 'package:timely/widgets/employee_avatar.dart';

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
          child: EmployeeAvatar(
            fullName: employeeName,
            imageUrl: employeeImageUrl,
            radius: 24,
          ),
        ),
      ],
    );
  }
}
