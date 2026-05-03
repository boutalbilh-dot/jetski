import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/depth_sample.dart';
import '../../core/services/alert_engine.dart';
import '../../core/theme/app_theme.dart';

Color colorForDepth(double depth, {required double warning, required double danger}) {
  return AppTheme.colorForLevel(
    AlertEngine.classify(
      depthMeters: depth,
      warningMeters: warning,
      dangerMeters: danger,
    ),
  );
}

PolylineLayer trackPolylineLayer(
  List<DepthSample> samples, {
  required double warning,
  required double danger,
}) {
  final polylines = <Polyline>[];
  List<LatLng> run = [];
  Color? runColor;

  void flush() {
    final color = runColor;
    if (run.length >= 2 && color != null) {
      polylines.add(Polyline(
        points: List<LatLng>.of(run),
        strokeWidth: 4,
        color: color,
      ));
    }
  }

  for (final s in samples) {
    if (s.latitude == null || s.longitude == null) {
      flush();
      run = [];
      runColor = null;
      continue;
    }
    final color = colorForDepth(s.depthMeters, warning: warning, danger: danger);
    final pt = LatLng(s.latitude!, s.longitude!);
    if (run.isEmpty) {
      run.add(pt);
      runColor = color;
    } else if (color == runColor) {
      run.add(pt);
    } else {
      // Colour change: close the previous run, start a new one with the
      // boundary point so the segments visually connect.
      flush();
      run = [run.last, pt];
      runColor = color;
    }
  }
  flush();
  return PolylineLayer(polylines: polylines);
}
