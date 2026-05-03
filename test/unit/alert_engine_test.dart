import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';

void main() {
  group('AlertEngine', () {
    late AlertEngine engine;

    setUp(() {
      engine = AlertEngine(
        warningMeters: 1.0,
        dangerMeters: 0.5,
        hysteresisMeters: 0.3,
      );
    });

    test('starts in safe level', () {
      expect(engine.level, AlertLevel.safe);
    });

    test('transitions to warning when depth drops below warning threshold', () {
      expect(engine.update(0.9), AlertLevel.warning);
      expect(engine.level, AlertLevel.warning);
    });

    test('transitions to danger when depth drops below danger threshold', () {
      engine.update(0.9);
      expect(engine.update(0.4), AlertLevel.danger);
    });

    test('safe transitions directly to danger when depth crashes past warning', () {
      expect(engine.update(0.3), AlertLevel.danger);
    });

    test('hysteresis: warning does not clear at exactly the threshold', () {
      engine.update(0.9); // -> warning
      // Threshold + hysteresis is 1.0 + 0.3 = 1.3 m. 1.05 m must stay warning.
      expect(engine.update(1.05), AlertLevel.warning);
      // 1.31 m clears the warning.
      expect(engine.update(1.31), AlertLevel.safe);
    });

    test('hysteresis: danger only clears above 0.5 + 0.3 = 0.8 m', () {
      engine.update(0.4); // -> danger
      expect(engine.update(0.6), AlertLevel.danger);
      expect(engine.update(0.81), AlertLevel.warning);
    });

    test('emits onTransition only on level changes', () {
      final transitions = <AlertLevel>[];
      engine.onTransition = transitions.add;
      engine.update(2.0);  // safe (no change, no transition)
      engine.update(0.9);  // -> warning
      engine.update(0.85); // still warning
      engine.update(0.4);  // -> danger
      engine.update(0.45); // still danger
      engine.update(2.0);  // -> safe
      expect(transitions, [
        AlertLevel.warning,
        AlertLevel.danger,
        AlertLevel.safe,
      ]);
    });
  });
}
