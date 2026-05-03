import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/services/depth_source.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('simulation -> depthStream -> alertLevel transitions to danger', () async {
    final container = ProviderContainer(overrides: [
      depthSourceProvider.overrideWith((ref) {
        final s = SimulationService(
          scenario: SimulationScenario.suddenDanger,
          tickInterval: const Duration(milliseconds: 5),
        );
        return s;
      }),
    ]);
    addTearDown(container.dispose);

    // Subscribe to the depth stream so the provider actually starts.
    final sub = container.listen(depthStreamProvider, (_, __) {});
    addTearDown(sub.close);
    // Subscribe to alertLevelProvider too so it consumes stream events as they arrive.
    final alertSub = container.listen(alertLevelProvider, (_, __) {});
    addTearDown(alertSub.close);

    // Wait until ~40 ticks elapse so we cross the suddenDanger transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final level = container.read(alertLevelProvider).valueOrNull;
    expect(level, AlertLevel.danger);
  });
}
