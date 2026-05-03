import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    label: Text('Sim'),
                    icon: Icon(Icons.science_outlined)),
                ButtonSegment(
                    value: SourceMode.bluetooth,
                    label: Text('Bluetooth'),
                    icon: Icon(Icons.bluetooth)),
                ButtonSegment(
                    value: SourceMode.wifi,
                    label: Text('WiFi'),
                    icon: Icon(Icons.wifi)),
              ],
              selected: {source.mode},
              onSelectionChanged: (s) => sourceNotifier.setMode(s.first),
            ),
          ),
          const SizedBox(height: 8),
          if (source.mode == SourceMode.simulation)
            _SimulationPanel(
              scenario: sim.scenario,
              onScenarioChanged: simNotifier.setScenario,
            )
          else if (source.mode == SourceMode.bluetooth)
            _BluetoothPanel(
              address: source.bluetoothAddress,
              onPick: () async {
                final addr = await showDialog<String>(
                  context: context,
                  builder: (_) => const BluetoothPickerDialog(),
                );
                if (addr != null) {
                  await sourceNotifier.setBluetoothAddress(addr);
                }
              },
              onForget: () => sourceNotifier.setBluetoothAddress(null),
            )
          else
            _WifiPanel(
              port: source.wifiPort,
              onPortChanged: sourceNotifier.setWifiPort,
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

class _SimulationPanel extends StatelessWidget {
  final SimulationScenario scenario;
  final void Function(SimulationScenario) onScenarioChanged;
  const _SimulationPanel({
    required this.scenario,
    required this.onScenarioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                value: scenario.name,
                items: SimulationScenario.values
                    .map((s) =>
                        DropdownMenuItem(value: s.name, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onScenarioChanged(SimulationScenario.values.byName(v));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BluetoothPanel extends StatelessWidget {
  final String? address;
  final VoidCallback onPick;
  final VoidCallback onForget;
  const _BluetoothPanel({
    required this.address,
    required this.onPick,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Sondeur Bluetooth'),
          subtitle: Text(address ?? 'Aucun appareil sélectionné'),
          trailing: TextButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Choisir'),
            onPressed: onPick,
          ),
        ),
        if (address != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.link_off),
              label: const Text("Oublier l'appareil"),
              onPressed: onForget,
            ),
          ),
      ],
    );
  }
}

class _WifiPanel extends StatefulWidget {
  final int port;
  final void Function(int) onPortChanged;
  const _WifiPanel({required this.port, required this.onPortChanged});

  @override
  State<_WifiPanel> createState() => _WifiPanelState();
}

class _WifiPanelState extends State<_WifiPanel> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.port.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text);
    if (v != null && v > 0 && v <= 65535) {
      widget.onPortChanged(v);
    } else {
      _ctrl.text = widget.port.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text('Sondeur WiFi (NMEA UDP)'),
          subtitle: Text(
            'Connectez votre téléphone au WiFi du sondeur (Deeper, '
            'Lowrance, passerelle marine…) puis activez l\'envoi NMEA '
            '0183 sur UDP dans son application.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Port UDP : '),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commit(),
                  onEditingComplete: _commit,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              const Text('(défaut : $kDefaultWifiNmeaPort)',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
