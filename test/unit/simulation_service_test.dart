import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/depth_source.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';

void main() {
  group('SimulationService', () {
    test('emits a stream of depths for the "approach" scenario', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      final samples = await svc.depthMeters.take(5).toList();
      expect(samples, hasLength(5));
      // Approach: starts deep, gets shallower over time.
      expect(samples.first, greaterThan(samples.last));
      await svc.stop();
    });

    test('manual scenario emits the value set via setManualDepth', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.manual,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      svc.setManualDepth(0.7);
      final v = await svc.depthMeters.first;
      expect(v, 0.7);
      await svc.stop();
    });

    test('implements DepthSource', () {
      final svc = SimulationService(scenario: SimulationScenario.approach);
      expect(svc, isA<DepthSource>());
    });

    test('cannot start twice', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      expect(() => svc.start(), throwsStateError);
      await svc.stop();
    });
  });
}
