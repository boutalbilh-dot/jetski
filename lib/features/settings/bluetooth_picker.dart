import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../core/services/bluetooth_service.dart';

/// Modal dialog that lists currently bonded Bluetooth devices and returns the
/// MAC address of the one the user picks (or null if cancelled). Devices are
/// expected to have been paired via the OS Settings — we don't initiate pairing.
class BluetoothPickerDialog extends StatefulWidget {
  const BluetoothPickerDialog({super.key});

  @override
  State<BluetoothPickerDialog> createState() => _BluetoothPickerDialogState();
}

class _BluetoothPickerDialogState extends State<BluetoothPickerDialog> {
  late Future<List<BluetoothDevice>> _future;

  @override
  void initState() {
    super.initState();
    _future = BluetoothService.bondedDevices();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un sondeur'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<BluetoothDevice>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Impossible de lister les appareils Bluetooth.\n'
                  '${snap.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final devices = snap.data ?? const [];
            if (devices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Aucun appareil appairé.\n"
                  "Appairez d'abord le sondeur depuis les réglages "
                  'Bluetooth de votre téléphone.',
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(d.name ?? '(sans nom)'),
                  subtitle: Text(d.address),
                  onTap: () => Navigator.of(context).pop(d.address),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
