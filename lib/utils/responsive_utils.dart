import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivo para todos los dispositivos
enum DeviceType { mobile, tablet, desktop }

class ResponsiveBreakpoints {
  // Breakpoints en píxeles lógicos
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;
}

class ResponsiveHelper {
  final BuildContext context;
  final Size screenSize;
  final double width;
  final double height;
  final Orientation orientation;

  ResponsiveHelper(this.context)
    : screenSize = MediaQuery.of(context).size,
      width = MediaQuery.of(context).size.width,
      height = MediaQuery.of(context).size.height,
      orientation = MediaQuery.of(context).orientation;

  /// Detecta el tipo de dispositivo basándose en el ancho de pantalla
  DeviceType get deviceType {
    if (width < ResponsiveBreakpoints.mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Verifica si es un dispositivo móvil
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Verifica si es una tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Verifica si es desktop
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Verifica si está en portrait
  bool get isPortrait => orientation == Orientation.portrait;

  /// Verifica si está en landscape
  bool get isLandscape => orientation == Orientation.landscape;

  /// Obtiene un valor responsivo basado en el tipo de dispositivo
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

  /// Padding responsivo basado en el dispositivo
  EdgeInsets get screenPadding {
    return responsiveValue(
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      desktop: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
    );
  }

  /// Spacing entre elementos
  double get spacing {
    return responsiveValue(mobile: 12, tablet: 20, desktop: 24);
  }

  /// Radio del avatar responsivo
  double get avatarRadius {
    return responsiveValue(mobile: 50, tablet: 60, desktop: 64);
  }

  /// Tamaño de iconos responsivo
  double get iconSize {
    return responsiveValue(mobile: 24, tablet: 26, desktop: 28);
  }

  /// Border radius responsivo
  double get borderRadius {
    return responsiveValue(mobile: 8, tablet: 10, desktop: 12);
  }
}

/// Extension para acceder fácilmente al ResponsiveHelper desde cualquier BuildContext
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
