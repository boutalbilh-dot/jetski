import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';

/// Small chip showing the current source's connection state. Hidden entirely
/// when the active source is the simulator or no source is wired up.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sourceConnectionStateProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final mode = ref.watch(sourceConfigProvider.select((c) => c.mode));
    final base = mode == SourceMode.wifi ? 'WiFi' : 'BT';

    final (icon, color, label) = switch (state) {
      SourceConnectionState.disconnected => (
        mode == SourceMode.wifi ? Icons.wifi_off : Icons.bluetooth_disabled,
        Colors.grey,
        '$base : déconnecté',
      ),
      SourceConnectionState.connecting => (
        mode == SourceMode.wifi ? Icons.wifi : Icons.bluetooth_searching,
        Colors.orange,
        '$base : connexion…',
      ),
      SourceConnectionState.connected => (
        mode == SourceMode.wifi ? Icons.wifi : Icons.bluetooth_connected,
        Colors.green,
        '$base : connecté',
      ),
      SourceConnectionState.error => (
        Icons.error_outline,
        Colors.red,
        '$base : erreur',
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
