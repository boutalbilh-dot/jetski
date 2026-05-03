import 'package:flutter/material.dart';
import '../services/alert_engine.dart';

class AppTheme {
  static const safeColor = Color(0xFF1A4D2E);
  static const warningColor = Color(0xFFE6A23C);
  static const dangerColor = Color(0xFFD63031);

  static Color colorForLevel(AlertLevel level) => switch (level) {
        AlertLevel.safe => safeColor,
        AlertLevel.warning => warningColor,
        AlertLevel.danger => dangerColor,
      };

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4D2E)),
    );
  }
}
