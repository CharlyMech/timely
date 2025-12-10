import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final double padding;
  final double borderRadius;
  final double elevation;
  final Color? color;
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
