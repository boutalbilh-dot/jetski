import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../core/services/bluetooth_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// Modal dialog that lists currently bonded Bluetooth devices and returns the
/// MAC address of the one the user picks (or null if cancelled). Pairing is
/// expected to have happened in the OS Settings — we don't initiate it.
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.pickerTitle),
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
                  l10n.pickerError(snap.error.toString()),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final devices = snap.data ?? const [];
            if (devices.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.pickerEmpty),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(d.name ?? l10n.noName),
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
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
