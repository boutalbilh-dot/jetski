import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/simulation_service.dart';
import 'bluetooth_picker.dart';
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
    final source = ref.watch(sourceConfigProvider);
    final sourceNotifier = ref.read(sourceConfigProvider.notifier);

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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Source de profondeur',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<SourceMode>(
              segments: const [
                ButtonSegment(
                    value: SourceMode.simulation,
                    label: Text('Simulation'),
                    icon: Icon(Icons.science_outlined)),
                ButtonSegment(
                    value: SourceMode.bluetooth,
                    label: Text('Bluetooth'),
                    icon: Icon(Icons.bluetooth)),
              ],
              selected: {source.mode},
              onSelectionChanged: (s) => sourceNotifier.setMode(s.first),
            ),
          ),
          if (source.mode == SourceMode.simulation) ...[
            const ListTile(
              title: Text('Mode simulation'),
              subtitle: Text('Émet des profondeurs fictives selon un scénario.'),
            ),
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
          ] else ...[
            ListTile(
              title: const Text('Sondeur'),
              subtitle: Text(source.bluetoothAddress ?? 'Aucun appareil sélectionné'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Choisir'),
                onPressed: () async {
                  final addr = await showDialog<String>(
                    context: context,
                    builder: (_) => const BluetoothPickerDialog(),
                  );
                  if (addr != null) {
                    await sourceNotifier.setBluetoothAddress(addr);
                  }
                },
              ),
            ),
            if (source.bluetoothAddress != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  icon: const Icon(Icons.link_off),
                  label: const Text('Oublier l\'appareil'),
                  onPressed: () => sourceNotifier.setBluetoothAddress(null),
                ),
              ),
          ],
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
