import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'track_layer.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();

  // Default camera target (Quebec City) used until the first GPS fix moves
  // the live marker. flutter_map's MapOptions only respects initialCenter
  // on the first build, so feeding it a reactive value would be wasted
  // rebuild work — child layers handle position updates themselves.
  static const _defaultCenter = LatLng(46.81, -71.21);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    final pos = ref.read(positionStreamProvider).valueOrNull;
    if (pos == null) return;
    _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retina = MediaQuery.of(context).devicePixelRatio > 1.0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: retina,
            userAgentPackageName: 'com.finan.jetski',
            maxNativeZoom: 19,
          ),
          const RepaintBoundary(child: _TrackLayerHost()),
          const _AccuracyLayer(),
          const _GpsMarkerLayer(),
          const _MapAttribution(),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _recenter,
        tooltip: l10n.mapRecenterTooltip,
        child: const Icon(Icons.my_location),
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
    // geolocator returns NaN heading or 0 speed when the device is still;
    // below ~0.5 m/s the heading is too noisy to be useful, so fall back
    // to a static dot.
    final showArrow = !pos.heading.isNaN && pos.speed > 0.5;
    return MarkerLayer(markers: [
      Marker(
        point: LatLng(pos.latitude, pos.longitude),
        width: 36,
        height: 36,
        child: RepaintBoundary(
          child: showArrow
              ? _DirectionalGpsMarker(headingDeg: pos.heading)
              : const _GpsMarker(),
        ),
      ),
    ]);
  }
}

/// Translucent halo whose radius is the GPS reported accuracy, in meters.
class _AccuracyLayer extends ConsumerWidget {
  const _AccuracyLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionStreamProvider).valueOrNull;
    if (pos == null) return const SizedBox.shrink();
    if (pos.accuracy.isNaN || pos.accuracy <= 0) {
      return const SizedBox.shrink();
    }
    return CircleLayer(circles: [
      CircleMarker(
        point: LatLng(pos.latitude, pos.longitude),
        radius: pos.accuracy,
        useRadiusInMeter: true,
        color: const Color(0x1A2196F3),
        borderColor: const Color(0x4D2196F3),
        borderStrokeWidth: 1,
      ),
    ]);
  }
}

class _DirectionalGpsMarker extends StatelessWidget {
  final double headingDeg;
  const _DirectionalGpsMarker({required this.headingDeg});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDeg * pi / 180,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.navigation,
            color: Color(0xFF1976D2), size: 22),
      ),
    );
  }
}

class _GpsMarker extends StatelessWidget {
  const _GpsMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();
  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '© OpenStreetMap • CARTO',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
