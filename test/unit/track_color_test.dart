import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/theme/app_theme.dart';
import 'package:projet_jetski/features/map/track_layer.dart';

void main() {
  group('colorForDepth', () {
    test('safe band -> safeColor', () {
      expect(colorForDepth(2.0, warning: 1.0, danger: 0.5), AppTheme.safeColor);
    });
    test('warning band -> warningColor', () {
      expect(colorForDepth(0.8, warning: 1.0, danger: 0.5), AppTheme.warningColor);
    });
    test('danger band -> dangerColor', () {
      expect(colorForDepth(0.3, warning: 1.0, danger: 0.5), AppTheme.dangerColor);
    });
  });
}
