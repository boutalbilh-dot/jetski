import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/simulation_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'bluetooth_picker.dart';
import 'threshold_slider.dart';

String scenarioLabel(AppLocalizations l10n, SimulationScenario s) =>
    switch (s) {
      SimulationScenario.approach => l10n.scenarioApproach,
      SimulationScenario.suddenDanger => l10n.scenarioSuddenDanger,
      SimulationScenario.unstable => l10n.scenarioUnstable,
      SimulationScenario.manual => l10n.scenarioManual,
    };

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final th = ref.watch(thresholdsProvider);
    final thNotifier = ref.read(thresholdsProvider.notifier);
    final sim = ref.watch(simSelectionProvider);
    final simNotifier = ref.read(simSelectionProvider.notifier);
    final unit = ref.watch(unitProvider);
    final unitNotifier = ref.read(unitProvider.notifier);
    final source = ref.watch(sourceConfigProvider);
    final sourceNotifier = ref.read(sourceConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ThresholdSlider(
            label: l10n.thresholdWarning,
            value: th.warningMeters,
            min: th.dangerMeters + 0.1,
            max: 5.0,
            onChanged: thNotifier.setWarning,
          ),
          ThresholdSlider(
            label: l10n.thresholdDanger,
            value: th.dangerMeters,
            min: 0.1,
            max: th.warningMeters - 0.1,
            onChanged: thNotifier.setDanger,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.sourceSectionTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<SourceMode>(
              segments: [
                ButtonSegment(
                    value: SourceMode.simulation,
                    label: Text(l10n.sourceModeSim),
                    icon: const Icon(Icons.science_outlined)),
                ButtonSegment(
                    value: SourceMode.bluetooth,
                    label: Text(l10n.sourceModeBt),
                    icon: const Icon(Icons.bluetooth)),
                ButtonSegment(
                    value: SourceMode.wifi,
                    label: Text(l10n.sourceModeWifi),
                    icon: const Icon(Icons.wifi)),
                ButtonSegment(
                    value: SourceMode.replay,
                    label: Text(l10n.sourceModeReplay),
                    icon: const Icon(Icons.history)),
              ],
              selected: {source.mode},
              onSelectionChanged: (s) => sourceNotifier.setMode(s.first),
            ),
          ),
          const SizedBox(height: 8),
          switch (source.mode) {
            SourceMode.simulation => _SimulationPanel(
                scenario: sim.scenario,
                onScenarioChanged: simNotifier.setScenario,
              ),
            SourceMode.bluetooth => _BluetoothPanel(
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
              ),
            SourceMode.wifi => _WifiPanel(
                port: source.wifiPort,
                onPortChanged: sourceNotifier.setWifiPort,
              ),
            SourceMode.replay => const _ReplayPanel(),
          },
          const Divider(),
          ListTile(
            title: Text(l10n.unitLabel),
            trailing: ToggleButtons(
              isSelected: [unit == DepthUnit.meters, unit == DepthUnit.feet],
              onPressed: (i) => unitNotifier
                  .setUnit(i == 0 ? DepthUnit.meters : DepthUnit.feet),
              children: [Text(l10n.unitMeters), Text(l10n.unitFeet)],
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(l10n.simulationPanelTitle),
          subtitle: Text(l10n.simulationPanelSubtitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(l10n.scenarioLabel),
              const SizedBox(width: 8),
              DropdownButton<SimulationScenario>(
                value: scenario,
                items: SimulationScenario.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(scenarioLabel(l10n, s)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onScenarioChanged(v);
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          title: Text(l10n.bluetoothPanelTitle),
          subtitle: Text(address ?? l10n.noDeviceSelected),
          trailing: TextButton.icon(
            icon: const Icon(Icons.search),
            label: Text(l10n.chooseDevice),
            onPressed: onPick,
          ),
        ),
        if (address != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.link_off),
              label: Text(l10n.forgetDevice),
              onPressed: onForget,
            ),
          ),
      ],
    );
  }
}

class _ReplayPanel extends ConsumerWidget {
  const _ReplayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final countAsync = ref.watch(replayAvailableCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(l10n.replayPanelTitle),
          subtitle: Text(l10n.replayPanelSubtitle),
        ),
        countAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (count) {
            if (count == 0) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  l10n.replayNoDataYet,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            }
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.replaySamplesAvailable(count)),
            );
          },
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(l10n.wifiPanelTitle),
          subtitle: Text(l10n.wifiPanelSubtitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(l10n.wifiPortLabel),
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
              Text(l10n.wifiPortDefaultHint(kDefaultWifiNmeaPort),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
