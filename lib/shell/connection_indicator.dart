import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Small chip showing the current source's connection state. Hidden entirely
/// when the active source is the simulator or no source is wired up.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sourceConnectionStateProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final mode = ref.watch(sourceConfigProvider.select((c) => c.mode));
    final l10n = AppLocalizations.of(context)!;
    final transport = mode == SourceMode.wifi ? 'WiFi' : 'BT';
    final isWifi = mode == SourceMode.wifi;

    final (icon, color, label) = switch (state) {
      SourceConnectionState.disconnected => (
        isWifi ? Icons.wifi_off : Icons.bluetooth_disabled,
        Colors.grey,
        l10n.connStatusDisconnected(transport),
      ),
      SourceConnectionState.connecting => (
        isWifi ? Icons.wifi : Icons.bluetooth_searching,
        Colors.orange,
        l10n.connStatusConnecting(transport),
      ),
      SourceConnectionState.connected => (
        isWifi ? Icons.wifi : Icons.bluetooth_connected,
        Colors.green,
        l10n.connStatusConnected(transport),
      ),
      SourceConnectionState.error => (
        Icons.error_outline,
        Colors.red,
        l10n.connStatusError(transport),
      ),
    };

    return Material(
      color: const Color(0x8C000000), // ~55% black, precomputed → const
      borderRadius: const BorderRadius.all(Radius.circular(16)),
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
