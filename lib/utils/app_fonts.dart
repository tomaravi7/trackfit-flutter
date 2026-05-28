import 'package:flutter/material.dart';

class AppFonts {
  static bool useGoogleFonts = true;

  static TextStyle inter({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    final family = useGoogleFonts ? 'Inter' : 'Roboto';
    return (textStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: family,
    );
  }

  static TextStyle plusJakartaSans({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    final family = useGoogleFonts ? 'Plus Jakarta Sans' : 'Roboto';
    return (textStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: family,
    );
  }

  static TextTheme interTextTheme([TextTheme? textTheme]) {
    final base = textTheme ?? const TextTheme();
    if (!useGoogleFonts) {
      return base;
    }
    return base.apply(fontFamily: 'Inter');
  }
}
