import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'track_layer.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionStreamProvider).valueOrNull;
    final samples = ref.watch(allSamplesProvider).valueOrNull ?? const [];
    final th = ref.watch(thresholdsProvider);

    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(46.81, -71.21);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.finan.jetski',
          ),
          trackPolylineLayer(samples,
              warning: th.warningMeters, danger: th.dangerMeters),
          if (pos != null)
            MarkerLayer(markers: [
              Marker(
                point: LatLng(pos.latitude, pos.longitude),
                width: 16,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}
