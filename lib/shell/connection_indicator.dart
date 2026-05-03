import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../core/services/bluetooth_service.dart';

/// Small chip showing the Bluetooth connection state. Hidden entirely when
/// the active source is the simulator or there's no source.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bluetoothConnectionStateProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final (icon, color, label) = switch (state) {
      BluetoothConnectionState.disconnected => (
        Icons.bluetooth_disabled,
        Colors.grey,
        'Déconnecté',
      ),
      BluetoothConnectionState.connecting => (
        Icons.bluetooth_searching,
        Colors.orange,
        'Connexion…',
      ),
      BluetoothConnectionState.connected => (
        Icons.bluetooth_connected,
        Colors.green,
        'Connecté',
      ),
      BluetoothConnectionState.error => (
        Icons.error_outline,
        Colors.red,
        'Erreur',
      ),
    };

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
