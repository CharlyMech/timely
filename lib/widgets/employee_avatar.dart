import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

class EmployeeAvatar extends StatelessWidget {
  final String fullName;
  final String? imageUrl;
  final double? radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final bool useResponsiveSize;

  const EmployeeAvatar({
    super.key,
    required this.fullName,
    this.imageUrl,
    this.radius,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.useResponsiveSize = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    // Calcular el radio efectivo
    final effectiveRadius = useResponsiveSize
        ? (radius ?? responsive.avatarRadius)
        : (radius ?? 32.0);

    if (hasValidImage) {
      return _buildImageAvatar(theme, effectiveRadius);
    } else {
      return _buildInitialsAvatar(theme, effectiveRadius);
    }
  }

  Widget _buildImageAvatar(ThemeData theme, double effectiveRadius) {
    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor:
          backgroundColor ?? theme.primaryColor.withValues(alpha: 0.1),
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar image: $exception');
      },
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme, double effectiveRadius) {
    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      child: _buildInitialsText(theme, effectiveRadius),
    );
  }

  Widget _buildInitialsText(ThemeData theme, double effectiveRadius) {
    final initials = _getInitials(fullName);
    final textSize = fontSize ?? effectiveRadius * 0.5;

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
