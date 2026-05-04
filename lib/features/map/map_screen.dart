import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'track_layer.dart';

class _GpsMarker extends StatelessWidget {
  const _GpsMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  // Default camera target (Quebec City) used until the first GPS fix moves
  // the live marker. flutter_map's MapOptions only respects initialCenter
  // on the first build, so feeding it a reactive value would be wasted
  // rebuild work — child layers handle position updates themselves.
  static const _defaultCenter = LatLng(46.81, -71.21);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: FlutterMap(
        options: const MapOptions(
            initialCenter: _defaultCenter, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.finan.jetski',
          ),
          const _TrackLayerHost(),
          const _GpsMarkerLayer(),
        ],
      ),
    );
  }
}

/// Watches just the depth log + thresholds so the polyline rebuild doesn't
/// pay for unrelated position-stream churn.
class _TrackLayerHost extends ConsumerWidget {
  const _TrackLayerHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = ref.watch(allSamplesProvider).valueOrNull ?? const [];
    final warn =
        ref.watch(thresholdsProvider.select((t) => t.warningMeters));
    final danger =
        ref.watch(thresholdsProvider.select((t) => t.dangerMeters));
    return trackPolylineLayer(samples, warning: warn, danger: danger);
  }
}

/// Watches only the position so GPS ticks don't rebuild the polyline.
class _GpsMarkerLayer extends ConsumerWidget {
  const _GpsMarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionStreamProvider).valueOrNull;
    if (pos == null) return const MarkerLayer(markers: []);
    return MarkerLayer(markers: [
      Marker(
        point: LatLng(pos.latitude, pos.longitude),
        width: 16,
        height: 16,
        child: const RepaintBoundary(child: _GpsMarker()),
      ),
    ]);
  }
}
