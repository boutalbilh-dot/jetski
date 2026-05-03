import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/depth_sample.dart';
import '../services/alert_engine.dart';
import '../services/depth_log_service.dart';
import '../services/depth_logger.dart';
import '../services/depth_source.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
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
final depthSourceProvider = Provider<DepthSource>((ref) {
  final sim = ref.watch(simSelectionProvider);
  // For v0.1 we always return a simulation source. v0.2 will add Bluetooth selection.
  return SimulationService(scenario: sim.scenario);
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

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(RealBackend());
});

/// Listens to alertLevelProvider transitions and fires notifications. Created
/// once at app startup; never rebuilds.
final alertNotifierProvider = Provider<void>((ref) {
  final svc = ref.watch(notificationServiceProvider);
  ref.listen(alertLevelProvider, (prev, next) {
    final newLevel = next.valueOrNull;
    if (newLevel == null) return;
    if (prev?.valueOrNull == newLevel) return;
    svc.handleTransition(newLevel);
  });
});

enum DepthUnit { meters, feet }

class UnitNotifier extends StateNotifier<DepthUnit> {
  static const _key = 'unit';
  UnitNotifier() : super(DepthUnit.meters) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = DepthUnit.values.byName(p.getString(_key) ?? 'meters');
  }
  Future<void> setUnit(DepthUnit u) async {
    state = u;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, u.name);
  }
}

final unitProvider = StateNotifierProvider<UnitNotifier, DepthUnit>((ref) => UnitNotifier());

class SimSelection {
  final bool enabled;
  final SimulationScenario scenario;
  const SimSelection({this.enabled = true, this.scenario = SimulationScenario.approach});
  SimSelection copyWith({bool? enabled, SimulationScenario? scenario}) =>
      SimSelection(enabled: enabled ?? this.enabled, scenario: scenario ?? this.scenario);
}

class SimSelectionNotifier extends StateNotifier<SimSelection> {
  SimSelectionNotifier() : super(const SimSelection());
  void setEnabled(bool v) => state = state.copyWith(enabled: v);
  void setScenario(SimulationScenario s) => state = state.copyWith(scenario: s);
}

final simSelectionProvider =
    StateNotifierProvider<SimSelectionNotifier, SimSelection>((ref) => SimSelectionNotifier());

/// Stream of GPS positions; null if permission denied.
final positionStreamProvider = StreamProvider<Position?>((ref) async* {
  final svc = ref.watch(locationServiceProvider);
  final stream = await svc.start();
  if (stream == null) {
    yield null;
    return;
  }
  yield* stream;
});

/// All persisted samples (for the track layer). Refreshes on each new add via
/// [depthLogVersionProvider].
final allSamplesProvider = FutureProvider<List<DepthSample>>((ref) async {
  ref.watch(depthLogVersionProvider); // refresh trigger
  final svc = ref.watch(depthLogServiceProvider);
  return svc.all();
});

/// Bumped each time a new sample is persisted, to invalidate allSamplesProvider.
final depthLogVersionProvider = StateProvider<int>((ref) => 0);

/// Activates depth logging when watched. Lifetime tied to ProviderScope.
final depthLoggerProvider = Provider<DepthLogger>((ref) {
  final log = ref.watch(depthLogServiceProvider);
  // Open the DB lazily; the logger awaits each add so a missing open() throws.
  unawaited(log.open());
  final depth = ref.watch(depthStreamProvider.stream);
  final pos = ref.watch(positionStreamProvider.stream).map(
        (p) => p == null ? null : (p.latitude, p.longitude),
      );
  // v0.1: depth is always sourced from the simulator. v0.2 will branch on
  // Bluetooth availability.
  final logger = DepthLogger(
    logService: log,
    depthStream: depth,
    positionStream: pos,
    onCommit: () =>
        ref.read(depthLogVersionProvider.notifier).update((v) => v + 1),
    source: SampleSource.simulated,
  );
  logger.start();
  ref.onDispose(logger.stop);
  return logger;
});
