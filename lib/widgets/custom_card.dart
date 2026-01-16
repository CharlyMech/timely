import 'package:flutter/material.dart';

/// A customizable card widget with tap functionality and configurable styling.
///
/// Provides a Material card with optional tap handling, rounded corners,
/// elevation, and custom dimensions. Wraps content with padding and
/// optionally an InkWell for tap effects.
class CustomCard extends StatelessWidget {
  /// The widget to display inside the card.
  final Widget child;

  /// Optional callback invoked when the card is tapped.
  final VoidCallback? onTap;

  /// Optional fixed height for the card.
  final double? height;

  /// Optional fixed width for the card.
  final double? width;

  /// Padding around the child widget.
  final double padding;

  /// Border radius for rounded corners.
  final double borderRadius;

  /// Elevation for the card's shadow.
  final double elevation;

  /// Optional background color for the card.
  final Color? color;

  /// Optional margin around the card.
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.width,
    this.padding = 16,
    this.borderRadius = 12,
    this.elevation = 1,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
      color: color,
      margin: margin,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(padding: EdgeInsets.all(padding), child: child),
            )
          : Padding(padding: EdgeInsets.all(padding), child: child),
    );

    if (height != null || width != null) {
      return SizedBox(height: height, width: width, child: card);
    }

    return card;
  }
}
