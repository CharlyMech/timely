import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Widget que aplica padding responsivo automático
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useScreenPadding;
  final bool useHorizontalOnly;
  final bool useVerticalOnly;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
    this.useScreenPadding = true,
    this.useHorizontalOnly = false,
    this.useVerticalOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    EdgeInsets effectivePadding;

    if (padding != null) {
      effectivePadding = padding!;
    } else if (useScreenPadding) {
      effectivePadding = responsive.screenPadding;
    } else if (useHorizontalOnly) {
      effectivePadding = EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
      );
    } else if (useVerticalOnly) {
      effectivePadding = EdgeInsets.symmetric(
        vertical: responsive.verticalPadding,
      );
    } else {
      effectivePadding = responsive.screenPadding;
    }

    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}

/// Widget que aplica spacing vertical responsivo
class ResponsiveVerticalSpace extends StatelessWidget {
  final double? height;

  const ResponsiveVerticalSpace({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return SizedBox(height: height ?? responsive.spacing);
  }
}

/// Widget que aplica spacing horizontal responsivo
class ResponsiveHorizontalSpace extends StatelessWidget {
  final double? width;

  const ResponsiveHorizontalSpace({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return SizedBox(width: width ?? responsive.spacing);
  }
}

/// Container con ancho máximo responsivo para contenido
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.centerContent = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    Widget content = Container(
      constraints: BoxConstraints(
        maxWidth: responsive.maxContentWidth,
      ),
      padding: padding,
      child: child,
    );

    if (centerContent && responsive.isDesktop) {
      content = Center(child: content);
    }

    return content;
  }
}
