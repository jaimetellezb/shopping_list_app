import 'package:flutter/material.dart';

/// Paleta centralizada de la app. Los widgets deben usar estas constantes
/// (o el [ColorScheme] del tema) en lugar de literales hex repartidos.
abstract final class AppColors {
  static const primary = Color(0xFF4BDB88);
  static const secondary = Color(0xFF6C3FA0);

  static const lightScaffold = Color(0xFFF5F7F5);
  static const lightInk = Color(0xFF1B1B1B);

  static const darkScaffold = Color(0xFF101413);
  static const darkSurface = Color(0xFF1A201D);
  static const darkInk = Color(0xFFE9EDEA);
}
