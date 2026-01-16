import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Displays an employee's avatar as a circular image or initials.
///
/// Shows the employee's image if available, otherwise displays their initials
/// extracted from their full name. Supports responsive sizing and custom colors.
class EmployeeAvatar extends StatelessWidget {
  /// Full name of the employee for generating initials.
  final String fullName;

  /// Optional URL to the employee's avatar image.
  final String? imageUrl;

  /// Optional custom radius for the avatar circle.
  final double? radius;

  /// Optional custom background color.
  final Color? backgroundColor;

  /// Optional custom text color for initials.
  final Color? textColor;

  /// Optional custom font size for initials text.
  final double? fontSize;

  /// Whether to use responsive sizing based on device type.
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

  /// Builds an avatar using the employee's image from a network URL.
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

  /// Builds an avatar using the employee's initials.
  Widget _buildInitialsAvatar(ThemeData theme, double effectiveRadius) {
    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      child: _buildInitialsText(theme, effectiveRadius),
    );
  }

  /// Builds the text widget displaying the employee's initials.
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

  /// Extracts initials from a full name.
  ///
  /// Returns first letter of first name and first letter of last name.
  /// Returns '?' if name is empty or invalid.
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
