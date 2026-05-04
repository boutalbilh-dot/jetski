import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/depth_sample.dart';
import '../services/alert_engine.dart';
import '../services/bluetooth_service.dart';
import '../services/depth_log_service.dart';
import '../services/depth_logger.dart';
import '../services/depth_source.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/null_depth_source.dart';
import '../services/replay_depth_source.dart';
import '../services/simulation_service.dart';
import '../services/wifi_nmea_service.dart';
export '../services/replay_depth_source.dart' show kReplayDefaultLookback;

/// Centralised SharedPreferences keys.
class _PrefsKeys {
  static const thresholdWarn = 'th.warn';
  static const thresholdDanger = 'th.danger';
  static const unit = 'unit';
  static const simScenario = 'sim.scenario';
  static const sourceMode = 'src.mode';
  static const bluetoothAddress = 'src.bt.address';
  static const wifiPort = 'src.wifi.port';
}

/// Default UDP port for NMEA 0183-over-WiFi. 10110 is the de-facto standard
/// used by OpenCPN, Navionics, Yacht Devices, Digital Yacht and most marine
/// WiFi gateways. Deeper sonars let the user pick any port.
const int kDefaultWifiNmeaPort = 10110;

enum SourceMode { simulation, bluetooth, wifi, replay }

class SourceConfig {
  final SourceMode mode;
  final String? bluetoothAddress;
  final int wifiPort;
  const SourceConfig({
    this.mode = SourceMode.simulation,
    this.bluetoothAddress,
    this.wifiPort = kDefaultWifiNmeaPort,
  });
  SourceConfig copyWith({
    SourceMode? mode,
    String? bluetoothAddress,
    int? wifiPort,
  }) =>
      SourceConfig(
        mode: mode ?? this.mode,
        bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
        wifiPort: wifiPort ?? this.wifiPort,
      );
}

class SourceConfigNotifier extends StateNotifier<SourceConfig> {
  SourceConfigNotifier() : super(const SourceConfig()) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final modeStr = p.getString(_PrefsKeys.sourceMode);
    var mode = SourceMode.values
            .where((m) => m.name == modeStr)
            .firstOrNull ??
        SourceMode.simulation;
    // BT mode is no longer exposed in this build (flutter_bluetooth_serial
    // dropped, no BLE bridge yet). Migrate any legacy install silently.
    if (mode == SourceMode.bluetooth) {
      mode = SourceMode.simulation;
      await p.setString(_PrefsKeys.sourceMode, mode.name);
    }
    final addr = p.getString(_PrefsKeys.bluetoothAddress);
    final port = p.getInt(_PrefsKeys.wifiPort) ?? kDefaultWifiNmeaPort;
    state = SourceConfig(mode: mode, bluetoothAddress: addr, wifiPort: port);
  }

  Future<void> setMode(SourceMode mode) async {
    state = state.copyWith(mode: mode);
    final p = await SharedPreferences.getInstance();
    await p.setString(_PrefsKeys.sourceMode, mode.name);
  }

  Future<void> setBluetoothAddress(String? address) async {
    state = SourceConfig(
      mode: state.mode,
      bluetoothAddress: address,
      wifiPort: state.wifiPort,
    );
    final p = await SharedPreferences.getInstance();
    if (address == null) {
      await p.remove(_PrefsKeys.bluetoothAddress);
    } else {
      await p.setString(_PrefsKeys.bluetoothAddress, address);
    }
  }

  Future<void> setWifiPort(int port) async {
    state = state.copyWith(wifiPort: port);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_PrefsKeys.wifiPort, port);
  }
}

final sourceConfigProvider =
    StateNotifierProvider<SourceConfigNotifier, SourceConfig>(
        (ref) => SourceConfigNotifier());

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
  ThresholdsNotifier() : super(const Thresholds()) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = Thresholds(
      warningMeters: p.getDouble(_PrefsKeys.thresholdWarn) ?? 1.0,
      dangerMeters: p.getDouble(_PrefsKeys.thresholdDanger) ?? 0.5,
    );
  }
  Future<void> setWarning(double v) async {
    state = state.copyWith(warningMeters: v);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_PrefsKeys.thresholdWarn, v);
  }
  Future<void> setDanger(double v) async {
    state = state.copyWith(dangerMeters: v);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_PrefsKeys.thresholdDanger, v);
  }
}

final thresholdsProvider =
    StateNotifierProvider<ThresholdsNotifier, Thresholds>((ref) => ThresholdsNotifier());

/// Currently selected depth source. Rebuilt only when source mode, BT
/// address, or WiFi port changes (rare, user-driven). Within simulation mode,
/// scenario changes are pushed via setScenario() so the rest of the pipeline
/// (engine, logger) survives.
final depthSourceProvider = Provider<DepthSource>((ref) {
  final mode = ref.watch(sourceConfigProvider.select((c) => c.mode));
  final btAddress =
      ref.watch(sourceConfigProvider.select((c) => c.bluetoothAddress));
  final wifiPort = ref.watch(sourceConfigProvider.select((c) => c.wifiPort));

  switch (mode) {
    case SourceMode.simulation:
      final initial = ref.read(simSelectionProvider).scenario;
      final src = SimulationService(scenario: initial);
      ref.listen<SimSelection>(simSelectionProvider, (_, next) {
        src.setScenario(next.scenario);
      });
      return src;

    case SourceMode.bluetooth:
      if (btAddress == null || btAddress.isEmpty) {
        return NullDepthSource();
      }
      return BluetoothService(btAddress);

    case SourceMode.wifi:
      return WifiNmeaService(port: wifiPort);

    case SourceMode.replay:
      return ReplayDepthSource(
        logService: ref.read(depthLogServiceProvider),
      );
  }
});

/// Generic source-connection state surfaced to the UI. Yields null when the
/// active source is the simulator or the no-op source so the indicator can
/// hide.
enum SourceConnectionState { disconnected, connecting, connected, error }

final sourceConnectionStateProvider =
    StreamProvider<SourceConnectionState?>((ref) {
  final src = ref.watch(depthSourceProvider);
  if (src is BluetoothService) {
    return src.connectionState.map(_mapBt).startWith(_mapBt(src.currentState));
  }
  if (src is WifiNmeaService) {
    return src.connectionState.map(_mapWifi).startWith(_mapWifi(src.currentState));
  }
  return Stream.value(null);
});

SourceConnectionState _mapBt(BluetoothConnectionState s) => switch (s) {
      BluetoothConnectionState.disconnected => SourceConnectionState.disconnected,
      BluetoothConnectionState.connecting => SourceConnectionState.connecting,
      BluetoothConnectionState.connected => SourceConnectionState.connected,
      BluetoothConnectionState.error => SourceConnectionState.error,
    };

SourceConnectionState _mapWifi(WifiConnectionState s) => switch (s) {
      WifiConnectionState.idle => SourceConnectionState.disconnected,
      WifiConnectionState.listening => SourceConnectionState.connected,
      WifiConnectionState.error => SourceConnectionState.error,
    };

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final depthLogServiceProvider = Provider((ref) {
  final svc = DepthLogService();
  ref.onDispose(svc.close);
  return svc;
});

/// Number of `real` samples in the replay lookback window. The settings
/// panel shows this so the user knows whether replay mode has anything to
/// play before they switch to it. Refreshed on each new logger commit so it
/// stays in sync with the live recording session.
final replayAvailableCountProvider = FutureProvider<int>((ref) async {
  ref.watch(depthLogVersionProvider);
  final svc = ref.watch(depthLogServiceProvider);
  // open() is idempotent; calling here covers the case where the user opens
  // settings before any other screen has triggered logger startup.
  await svc.open();
  final now = DateTime.now().toUtc();
  return svc.count(
    from: now.subtract(kReplayDefaultLookback),
    to: now,
    source: SampleSource.real,
  );
});

/// Underlying depth stream from the active source. The simulator and the
/// future Bluetooth source both expose broadcast streams, so multiple
/// listeners are safe.
final depthBroadcastProvider = Provider<Stream<double>>((ref) {
  final src = ref.watch(depthSourceProvider);
  unawaited(src.start().catchError((Object e, StackTrace st) {
    debugPrint('depthSource.start() failed: $e\n$st');
  }));
  ref.onDispose(() => unawaited(src.stop()));
  return src.depthMeters;
});

/// Stream of depth values emitted by the current source.
final depthStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(depthBroadcastProvider);
});

/// Long-lived AlertEngine. Thresholds are pushed via setThresholds() rather
/// than recreating the engine, so hysteresis state survives slider drags.
final alertEngineProvider = Provider<AlertEngine>((ref) {
  final initial = ref.read(thresholdsProvider);
  final engine = AlertEngine(
    warningMeters: initial.warningMeters,
    dangerMeters: initial.dangerMeters,
  );
  ref.listen<Thresholds>(thresholdsProvider, (_, next) {
    engine.setThresholds(
      warningMeters: next.warningMeters,
      dangerMeters: next.dangerMeters,
    );
  });
  return engine;
});

final alertLevelStreamProvider = Provider<Stream<AlertLevel>>((ref) {
  final engine = ref.watch(alertEngineProvider);
  final source = ref.watch(depthBroadcastProvider);
  return source.map(engine.update);
});

/// Live alert level driven by the depth stream.
final alertLevelProvider = StreamProvider<AlertLevel>((ref) {
  return ref.watch(alertLevelStreamProvider);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(RealBackend());
});

/// Listens to alertLevelProvider transitions and fires notifications.
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
  UnitNotifier() : super(DepthUnit.meters) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = DepthUnit.values.byName(p.getString(_PrefsKeys.unit) ?? 'meters');
  }
  Future<void> setUnit(DepthUnit u) async {
    state = u;
    final p = await SharedPreferences.getInstance();
    await p.setString(_PrefsKeys.unit, u.name);
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
  SimSelectionNotifier() : super(const SimSelection()) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_PrefsKeys.simScenario);
    if (stored == null) return;
    final scenario = SimulationScenario.values
        .where((s) => s.name == stored)
        .firstOrNull;
    if (scenario != null) {
      state = state.copyWith(scenario: scenario);
    }
  }
  void setEnabled(bool v) => state = state.copyWith(enabled: v);
  Future<void> setScenario(SimulationScenario s) async {
    state = state.copyWith(scenario: s);
    final p = await SharedPreferences.getInstance();
    await p.setString(_PrefsKeys.simScenario, s.name);
  }
}

final simSelectionProvider =
    StateNotifierProvider<SimSelectionNotifier, SimSelection>((ref) => SimSelectionNotifier());

/// Underlying position stream from [LocationService], adapted to a broadcast
/// stream so multiple consumers (`positionStreamProvider` + `depthLoggerProvider`)
/// can subscribe to a single permission prompt + position stream.
final positionBroadcastProvider = Provider<Stream<Position?>>((ref) {
  final svc = ref.watch(locationServiceProvider);
  final controller = StreamController<Position?>.broadcast();
  StreamSubscription<Position>? sub;
  () async {
    final stream = await svc.start();
    if (controller.isClosed) return;
    if (stream == null) {
      controller.add(null);
      return;
    }
    sub = stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
  }();
  ref.onDispose(() async {
    await sub?.cancel();
    if (!controller.isClosed) await controller.close();
  });
  return controller.stream;
});

/// Stream of GPS positions; null if permission denied.
final positionStreamProvider = StreamProvider<Position?>((ref) {
  return ref.watch(positionBroadcastProvider);
});

/// Wall-clock instant the current app session began. Used to scope the map
/// track to the current ride, so old persisted samples don't bloat memory.
final sessionStartProvider = Provider<DateTime>((ref) => DateTime.now().toUtc());

/// In-memory accumulator backing [allSamplesProvider] — avoids re-loading the
/// entire session from SQLite on every commit (which is O(N) per 2 s tick).
/// Holds the latest snapshot plus a cursor so the next refresh only fetches
/// rows newer than the last one we saw.
class _SessionSamplesCache {
  List<DepthSample> samples = const [];
  int lastCursorMs = 0;
}

final _sessionSamplesCacheProvider =
    Provider<_SessionSamplesCache>((ref) => _SessionSamplesCache());

/// Samples from the current session, refreshed when the logger commits a batch.
/// Internally fetches only the delta since the last commit, then appends to a
/// cached list — keeps the map redraw cost flat as the session grows.
final allSamplesProvider = FutureProvider<List<DepthSample>>((ref) async {
  ref.watch(depthLogVersionProvider);
  final svc = ref.watch(depthLogServiceProvider);
  final start = ref.watch(sessionStartProvider);
  final cache = ref.watch(_sessionSamplesCacheProvider);

  final fromMs = cache.lastCursorMs == 0
      ? DepthSample.encodeTimestamp(start)
      : cache.lastCursorMs + 1;
  final now = DateTime.now().toUtc();
  if (DepthSample.encodeTimestamp(now) < fromMs) return cache.samples;

  final delta = await svc.range(
    from: DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true),
    to: now,
  );
  if (delta.isEmpty) return cache.samples;

  cache.samples = [...cache.samples, ...delta];
  cache.lastCursorMs = DepthSample.encodeTimestamp(cache.samples.last.timestamp);
  return cache.samples;
});

/// Bumped each time the logger commits a batch, to invalidate allSamplesProvider.
final depthLogVersionProvider = StateProvider<int>((ref) => 0);

/// Activates depth logging when watched. Lifetime tied to ProviderScope.
final depthLoggerProvider = Provider<DepthLogger>((ref) {
  final log = ref.watch(depthLogServiceProvider);
  final depth = ref.watch(depthBroadcastProvider);
  final pos = ref.watch(positionBroadcastProvider).map(
        (p) => p == null ? null : (p.latitude, p.longitude),
      );
  final mode = ref.watch(sourceConfigProvider.select((c) => c.mode));
  final logger = DepthLogger(
    logService: log,
    depthStream: depth,
    positionStream: pos,
    onCommit: () =>
        ref.read(depthLogVersionProvider.notifier).update((v) => v + 1),
    // Real sensors mark samples as real; sim & replay are synthesized.
    source: (mode == SourceMode.bluetooth || mode == SourceMode.wifi)
        ? SampleSource.real
        : SampleSource.simulated,
  );
  unawaited(logger.start().catchError((Object e, StackTrace st) {
    debugPrint('depthLogger.start() failed: $e\n$st');
  }));
  ref.onDispose(logger.stop);
  return logger;
});
