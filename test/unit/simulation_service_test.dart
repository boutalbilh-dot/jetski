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
        tickInterval: const Duration(seconds: 1), // long interval — we want setManualDepth to drive emission
      );
      await svc.start();
      // Listen before mutating to avoid any race; setManualDepth pushes immediately.
      final next = svc.depthMeters.first;
      svc.setManualDepth(0.7);
      expect(await next, 0.7);
      await svc.stop();
    });

    test('stop() closes the stream', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      // Take 1 sample to confirm it's emitting
      await svc.depthMeters.first;
      await svc.stop();
      // After stop(), the stream is done. .toList() returns the buffered events
      // and resolves once the stream closes. With no new subscriber, simply check
      // the stream is closed by re-listening and waiting for done.
      await svc.depthMeters.toList(); // does not hang
    });

    test('implements DepthSource', () {
      final svc = SimulationService(scenario: SimulationScenario.approach);
      expect(svc, isA<DepthSource>());
    });

    test('setScenario switches the active scenario without restarting', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.manual,
        tickInterval: const Duration(milliseconds: 5),
      );
      await svc.start();
      svc.setManualDepth(2.0);
      // Drain a couple of ticks at the manual value.
      final manualSample = await svc.depthMeters.first;
      expect(manualSample, 2.0);
      svc.setScenario(SimulationScenario.suddenDanger);
      // Tick was reset, so first ~30 ticks emit 3.0.
      final afterSwitch = await svc.depthMeters.first;
      expect(afterSwitch, 3.0);
      await svc.stop();
    });

    test('cannot start twice', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      expect(svc.start, throwsStateError);
      await svc.stop();
    });
  });
}
