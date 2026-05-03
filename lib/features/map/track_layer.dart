import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/depth_sample.dart';
import '../../core/theme/app_theme.dart';

Color colorForDepth(double depth, {required double warning, required double danger}) {
  if (depth <= danger) return AppTheme.dangerColor;
  if (depth <= warning) return AppTheme.warningColor;
  return AppTheme.safeColor;
}

PolylineLayer trackPolylineLayer(
  List<DepthSample> samples, {
  required double warning,
  required double danger,
}) {
  final polylines = <Polyline>[];
  for (var i = 1; i < samples.length; i++) {
    final a = samples[i - 1];
    final b = samples[i];
    if (a.latitude == null || a.longitude == null) continue;
    if (b.latitude == null || b.longitude == null) continue;
    polylines.add(Polyline(
      points: [
        LatLng(a.latitude!, a.longitude!),
        LatLng(b.latitude!, b.longitude!),
      ],
      strokeWidth: 4,
      color: colorForDepth(b.depthMeters, warning: warning, danger: danger),
    ));
  }
  return PolylineLayer(polylines: polylines);
}
