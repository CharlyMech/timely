import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivo para todos los dispositivos
enum DeviceType { mobile, tablet, desktop }

enum DeviceOrientation { portrait, landscape }

class ResponsiveBreakpoints {
  // Breakpoints en píxeles lógicos
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;

  // Breakpoints para altura (útil para detectar zoom excesivo)
  static const double minRecommendedHeight = 400;
  static const double tabletMinHeight = 600;

  // Factores de escala de texto seguros
  static const double minTextScaleFactor = 0.8;
  static const double maxTextScaleFactor = 1.3;
}

class ResponsiveHelper {
  final BuildContext context;
  final Size screenSize;
  final double width;
  final double height;
  final Orientation orientation;
  final double textScaleFactor;
  final double devicePixelRatio;

  ResponsiveHelper(this.context)
    : screenSize = MediaQuery.of(context).size,
      width = MediaQuery.of(context).size.width,
      height = MediaQuery.of(context).size.height,
      orientation = MediaQuery.of(context).orientation,
      textScaleFactor = MediaQuery.of(context).textScaleFactor,
      devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

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

  /// Detecta si el dispositivo está en orientación portrait o landscape
  DeviceOrientation get deviceOrientation {
    return orientation == Orientation.portrait
        ? DeviceOrientation.portrait
        : DeviceOrientation.landscape;
  }

  /// Verifica si es un dispositivo móvil
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Verifica si es una tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Verifica si es desktop
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Verifica si está en portrait
  bool get isPortrait => deviceOrientation == DeviceOrientation.portrait;

  /// Verifica si está en landscape
  bool get isLandscape => deviceOrientation == DeviceOrientation.landscape;

  /// Verifica si la altura es muy pequeña (posible zoom excesivo)
  bool get hasLimitedHeight =>
      height < ResponsiveBreakpoints.minRecommendedHeight;

  /// Verifica si el texto tiene un factor de escala alto
  bool get hasLargeTextScale =>
      textScaleFactor > ResponsiveBreakpoints.maxTextScaleFactor;

  /// Verifica si hay problemas de espacio vertical
  bool get hasVerticalSpaceConstraint =>
      hasLimitedHeight || (isLandscape && height < 500);

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

  /// Obtiene el número de columnas para un grid responsivo
  int get gridColumns {
    if (isMobile) {
      // En móvil portrait solo 1 columna para evitar overflow
      return isPortrait ? 1 : 2;
    } else if (isTablet) {
      return isPortrait ? 2 : 3;
    } else {
      return isPortrait ? 3 : 4;
    }
  }

  /// Calcula el aspect ratio óptimo para cards
  double get cardAspectRatio {
    if (hasVerticalSpaceConstraint) {
      return 1.5; // Más ancho que alto cuando hay poco espacio vertical
    }

    // En móvil portrait con 1 columna, usar aspect ratio más horizontal
    if (isMobile && isPortrait) {
      return 2.0; // Card más ancho que alto para aprovechar espacio
    }

    return isPortrait ? 1.2 : 1.4;
  }

  /// Padding responsivo basado en el dispositivo
  EdgeInsets get screenPadding {
    return responsiveValue(
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      desktop: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
    );
  }

  /// Padding horizontal responsivo
  double get horizontalPadding {
    return responsiveValue(mobile: 12, tablet: 32, desktop: 48);
  }

  /// Padding vertical responsivo
  double get verticalPadding {
    if (hasVerticalSpaceConstraint) {
      return 6; // Reducir padding vertical cuando hay poco espacio
    }
    return responsiveValue(mobile: 12, tablet: 20, desktop: 24);
  }

  /// Spacing entre elementos
  double get spacing {
    if (hasVerticalSpaceConstraint) {
      return 8;
    }
    return responsiveValue(mobile: 12, tablet: 20, desktop: 24);
  }

  /// Tamaño de fuente escalado de forma segura
  double scaledFontSize(double baseSize) {
    // Limita el factor de escala de texto para evitar UI rota
    final safeFactor = textScaleFactor.clamp(
      ResponsiveBreakpoints.minTextScaleFactor,
      ResponsiveBreakpoints.maxTextScaleFactor,
    );
    return baseSize * safeFactor;
  }

  /// Altura de componentes ajustada según espacio disponible
  double get componentHeight {
    if (hasVerticalSpaceConstraint) {
      return 48; // Altura mínima compacta
    }
    return responsiveValue(mobile: 56, tablet: 60, desktop: 64);
  }

  /// Radio del avatar responsivo
  double get avatarRadius {
    if (hasVerticalSpaceConstraint) {
      return 40;
    }
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

  /// Ancho máximo para contenido (para evitar líneas muy largas en pantallas grandes)
  double get maxContentWidth {
    return responsiveValue(mobile: double.infinity, tablet: 900, desktop: 1200);
  }

  /// Calcula el espacio de un grid de forma dinámica
  double get gridSpacing {
    if (hasVerticalSpaceConstraint) {
      return 8;
    }
    return responsiveValue(mobile: 12, tablet: 20, desktop: 24);
  }

  /// Calcula el alto de un AppBar responsivo
  double get appBarHeight {
    if (hasVerticalSpaceConstraint) {
      return 56;
    }
    return responsiveValue(mobile: 56, tablet: 64, desktop: 72);
  }

  /// Helper para crear un SizedBox responsivo vertical
  SizedBox get verticalSpace => SizedBox(height: spacing);

  /// Helper para crear un SizedBox responsivo horizontal
  SizedBox get horizontalSpace => SizedBox(width: spacing);
}

/// Extension para acceder fácilmente al ResponsiveHelper desde cualquier BuildContext
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
