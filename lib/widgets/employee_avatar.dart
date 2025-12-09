import 'package:flutter/material.dart';

class EmployeeAvatar extends StatelessWidget {
  final String fullName;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const EmployeeAvatar({
    super.key,
    required this.fullName,
    this.imageUrl,
    this.radius = 32,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasValidImage) {
      return _buildImageAvatar(theme);
    } else {
      return _buildInitialsAvatar(theme);
    }
  }

  Widget _buildImageAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1),
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar image: $exception');
      },
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      child: _buildInitialsText(theme),
    );
  }

  Widget _buildInitialsText(ThemeData theme) {
    final initials = _getInitials(fullName);
    final textSize = fontSize ?? radius * 0.5;

    return Text(
      initials,
      style: theme.textTheme.titleLarge?.copyWith(
        color: textColor ?? theme.colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: textSize,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty || parts[0].isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
