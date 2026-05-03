import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('simSelectionProvider restores the persisted scenario on relaunch',
      () async {
    SharedPreferences.setMockInitialValues({});

    // First "launch": user picks suddenDanger, which writes to prefs.
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    await c1.read(simSelectionProvider.notifier)
        .setScenario(SimulationScenario.suddenDanger);
    expect(c1.read(simSelectionProvider).scenario,
        SimulationScenario.suddenDanger);

    // Second "launch": fresh container, same prefs backing.
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    // Trigger notifier construction, then yield until _load resolves.
    c2.read(simSelectionProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c2.read(simSelectionProvider).scenario,
        SimulationScenario.suddenDanger);
  });

  test('defaults to approach scenario when nothing is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(simSelectionProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(simSelectionProvider).scenario, SimulationScenario.approach);
  });
}
