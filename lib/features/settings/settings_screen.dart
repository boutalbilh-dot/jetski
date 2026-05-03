import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/simulation_service.dart';
import 'threshold_slider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final th = ref.watch(thresholdsProvider);
    final thNotifier = ref.read(thresholdsProvider.notifier);
    final sim = ref.watch(simSelectionProvider);
    final simNotifier = ref.read(simSelectionProvider.notifier);
    final unit = ref.watch(unitProvider);
    final unitNotifier = ref.read(unitProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ThresholdSlider(
            label: 'Seuil avertissement',
            value: th.warningMeters,
            min: th.dangerMeters + 0.1,
            max: 5.0,
            onChanged: thNotifier.setWarning,
          ),
          ThresholdSlider(
            label: 'Seuil danger',
            value: th.dangerMeters,
            min: 0.1,
            max: th.warningMeters - 0.1,
            onChanged: thNotifier.setDanger,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Mode simulation'),
            subtitle: const Text('Émet une profondeur fake pour démo / dev'),
            value: sim.enabled,
            onChanged: simNotifier.setEnabled,
          ),
          if (sim.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Scénario : '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: sim.scenario.name,
                    items: SimulationScenario.values
                        .map((s) =>
                            DropdownMenuItem(value: s.name, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      simNotifier.setScenario(SimulationScenario.values.byName(v));
                    },
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Unité'),
            trailing: ToggleButtons(
              isSelected: [unit == DepthUnit.meters, unit == DepthUnit.feet],
              onPressed: (i) => unitNotifier
                  .setUnit(i == 0 ? DepthUnit.meters : DepthUnit.feet),
              children: const [Text('Mètres'), Text('Pieds')],
            ),
          ),
        ],
      ),
    );
  }
}
