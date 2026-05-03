import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_engine.dart';
import '../services/depth_log_service.dart';
import '../services/depth_source.dart';
import '../services/location_service.dart';
import '../services/simulation_service.dart';

class Thresholds {
  final double warningMeters;
  final double dangerMeters;
  const Thresholds({this.warningMeters = 1.0, this.dangerMeters = 0.5});

  Thresholds copyWith({double? warningMeters, double? dangerMeters}) =>
      Thresholds(
        warningMeters: warningMeters ?? this.warningMeters,
        dangerMeters: dangerMeters ?? this.dangerMeters,
      );
}

class ThresholdsNotifier extends StateNotifier<Thresholds> {
  static const _kWarn = 'th.warn';
  static const _kDanger = 'th.danger';
  ThresholdsNotifier() : super(const Thresholds()) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = Thresholds(
      warningMeters: p.getDouble(_kWarn) ?? 1.0,
      dangerMeters: p.getDouble(_kDanger) ?? 0.5,
    );
  }
  Future<void> setWarning(double v) async {
    state = state.copyWith(warningMeters: v);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kWarn, v);
  }
  Future<void> setDanger(double v) async {
    state = state.copyWith(dangerMeters: v);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kDanger, v);
  }
}

final thresholdsProvider =
    StateNotifierProvider<ThresholdsNotifier, Thresholds>((ref) => ThresholdsNotifier());

/// Currently selected depth source. Defaults to simulation.
final depthSourceProvider = StateProvider<DepthSource>((ref) {
  return SimulationService(scenario: SimulationScenario.approach);
});

final locationServiceProvider = Provider((ref) => LocationService());

final depthLogServiceProvider = Provider((ref) {
  final svc = DepthLogService();
  ref.onDispose(svc.close);
  return svc;
});

/// Stream of depth values emitted by the current source.
final depthStreamProvider = StreamProvider<double>((ref) {
  final src = ref.watch(depthSourceProvider);
  unawaited(src.start().catchError((_) {}));
  ref.onDispose(() => unawaited(src.stop()));
  return src.depthMeters;
});

/// Long-lived AlertEngine — preserved across depth events so hysteresis works.
/// Recreated when thresholds change (acceptable: new thresholds reset hysteresis).
final alertEngineProvider = Provider<AlertEngine>((ref) {
  final t = ref.watch(thresholdsProvider);
  return AlertEngine(
    warningMeters: t.warningMeters,
    dangerMeters: t.dangerMeters,
  );
});

/// Live alert level driven by the depth stream.
final alertLevelProvider = StreamProvider<AlertLevel>((ref) {
  final engine = ref.watch(alertEngineProvider);
  final stream = ref.watch(depthStreamProvider.stream);
  return stream.map(engine.update);
});
