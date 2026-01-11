import 'package:flutter/material.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Text widget que escala de forma segura con el textScaleFactor del sistema
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Si el textScaleFactor es muy alto, limitamos para evitar UI rota
    final limitedTextScale = responsive.textScaleFactor.clamp(
      ResponsiveBreakpoints.minTextScaleFactor,
      ResponsiveBreakpoints.maxTextScaleFactor,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: limitedTextScale,
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}

/// Helper para crear estilos de texto responsivos
class ResponsiveTextStyles {
  final BuildContext context;
  final ResponsiveHelper responsive;

  ResponsiveTextStyles(this.context) : responsive = ResponsiveHelper(context);

  TextStyle get headline1 => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 28,
          tablet: 32,
          desktop: 36,
        ),
        fontWeight: FontWeight.bold,
      );

  TextStyle get headline2 => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 24,
          tablet: 28,
          desktop: 32,
        ),
        fontWeight: FontWeight.bold,
      );

  TextStyle get headline3 => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 20,
          tablet: 22,
          desktop: 24,
        ),
        fontWeight: FontWeight.w600,
      );

  TextStyle get subtitle => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 16,
          tablet: 18,
          desktop: 20,
        ),
        fontWeight: FontWeight.w500,
      );

  TextStyle get body => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 14,
          tablet: 15,
          desktop: 16,
        ),
        fontWeight: FontWeight.normal,
      );

  TextStyle get caption => TextStyle(
        fontSize: responsive.responsiveValue(
          mobile: 12,
          tablet: 13,
          desktop: 14,
        ),
        fontWeight: FontWeight.normal,
      );
}

extension ResponsiveTextStylesExtension on BuildContext {
  ResponsiveTextStyles get textStyles => ResponsiveTextStyles(this);
}
