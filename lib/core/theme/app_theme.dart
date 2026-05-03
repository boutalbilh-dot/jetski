import 'package:flutter/material.dart';

class AppTheme {
  static const safeColor = Color(0xFF1A4D2E);
  static const warningColor = Color(0xFFE6A23C);
  static const dangerColor = Color(0xFFD63031);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4D2E)),
    );
  }
}
