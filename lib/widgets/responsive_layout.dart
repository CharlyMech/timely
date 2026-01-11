import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Layout wrapper que proporciona comportamiento responsivo base
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool applyPadding;
  final EdgeInsets? customPadding;
  final bool constrainWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.applyPadding = false,
    this.customPadding,
    this.constrainWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    Widget content = child;

    // Aplicar constrainWidth si es necesario (útil para desktop)
    if (constrainWidth) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.maxContentWidth,
          ),
          child: content,
        ),
      );
    }

    // Aplicar padding responsivo si se solicita
    if (applyPadding) {
      content = Padding(
        padding: customPadding ?? responsive.screenPadding,
        child: content,
      );
    }

    return content;
  }
}

/// Scaffold responsivo con comportamiento mejorado
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool applyBodyPadding;
  final EdgeInsets? customBodyPadding;
  final bool constrainBodyWidth;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.applyBodyPadding = false,
    this.customBodyPadding,
    this.constrainBodyWidth = false,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: ResponsiveLayout(
        applyPadding: applyBodyPadding,
        customPadding: customBodyPadding,
        constrainWidth: constrainBodyWidth,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Widget builder que proporciona información responsiva
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveHelper responsive)
      builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, context.responsive);
  }
}

/// Layout que cambia entre diferentes widgets según el tipo de dispositivo
class DeviceTypeLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const DeviceTypeLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    switch (responsive.deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Layout que cambia entre portrait y landscape
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;

  const OrientationLayout({
    super.key,
    required this.portrait,
    this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return responsive.isPortrait ? portrait : (landscape ?? portrait);
  }
}
