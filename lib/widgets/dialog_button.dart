import 'package:flutter/material.dart';
import 'package:timely/widgets/custom_card.dart';

/// A reusable button widget for dialogs.
///
/// Wraps a [CustomCard] with consistent padding and text styling,
/// designed for use as dialog action buttons (e.g., Cancel, Confirm).
class DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  const DialogButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      elevation: 0,
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
