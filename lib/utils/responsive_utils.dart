import 'package:flutter/material.dart';

/// Defines device types based on screen width.
enum DeviceType {
  /// Mobile devices (< 600 logical pixels).
  mobile,

  /// Tablet devices (600-1024 logical pixels).
  tablet,

  /// Desktop devices (>= 1025 logical pixels).
  desktop
}

/// Contains responsive breakpoint constants in logical pixels.
class ResponsiveBreakpoints {
  /// Maximum width for mobile devices.
  static const double mobileMaxWidth = 600;

  /// Maximum width for tablet devices.
  static const double tabletMaxWidth = 1024;

  /// Minimum width for desktop devices.
  static const double desktopMinWidth = 1025;
}

/// Helper class for responsive design calculations and device detection.
///
/// Provides utilities for detecting device types, orientation, and
/// calculating responsive values for spacing, sizing, and padding.
///
/// Usage:
/// ```dart
/// final responsive = context.responsive;
/// if (responsive.isMobile) {
///   // Mobile-specific layout
/// }
/// final padding = responsive.screenPadding;
/// ```
class ResponsiveHelper {
  /// The build context for accessing media query data.
  final BuildContext context;

  /// The current screen size.
  final Size screenSize;

  /// The current screen width in logical pixels.
  final double width;

  /// The current screen height in logical pixels.
  final double height;

  /// The current device orientation.
  final Orientation orientation;

  ResponsiveHelper(this.context)
    : screenSize = MediaQuery.of(context).size,
      width = MediaQuery.of(context).size.width,
      height = MediaQuery.of(context).size.height,
      orientation = MediaQuery.of(context).orientation;

  /// Detects the device type based on screen width.
  DeviceType get deviceType {
    if (width < ResponsiveBreakpoints.mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Returns `true` if the device is mobile-sized.
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Returns `true` if the device is tablet-sized.
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Returns `true` if the device is desktop-sized.
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Returns `true` if the device is in portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;

  /// Returns `true` if the device is in landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Returns a responsive value based on the device type.
  ///
  /// Provide values for mobile, tablet, and desktop. If tablet or desktop
  /// values are not provided, they fall back to mobile value.
  ///
  /// Example:
  /// ```dart
  /// final fontSize = responsive.responsiveValue(
  ///   mobile: 14.0,
  ///   tablet: 16.0,
  ///   desktop: 18.0,
  /// );
  /// ```
  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Returns responsive screen padding based on device type.
  EdgeInsets get screenPadding {
    return responsiveValue(
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      desktop: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
    );
  }

  /// Returns responsive spacing between elements.
  double get spacing {
    return responsiveValue(mobile: 12, tablet: 20, desktop: 24);
  }

  /// Returns responsive avatar radius.
  double get avatarRadius {
    return responsiveValue(mobile: 50, tablet: 60, desktop: 64);
  }

  /// Returns responsive icon size.
  double get iconSize {
    return responsiveValue(mobile: 24, tablet: 26, desktop: 28);
  }

  /// Returns responsive border radius.
  double get borderRadius {
    return responsiveValue(mobile: 8, tablet: 10, desktop: 12);
  }
}

/// Extension on [BuildContext] for easy access to [ResponsiveHelper].
///
/// Usage:
/// ```dart
/// final responsive = context.responsive;
/// if (responsive.isMobile) { ... }
/// ```
extension ResponsiveContext on BuildContext {
  /// Returns a [ResponsiveHelper] instance for this context.

  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
