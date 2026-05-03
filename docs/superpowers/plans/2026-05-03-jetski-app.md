# Projet Jetski — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile app (iOS + Android) that reads depth from a Bluetooth NMEA 0183 depth sounder, displays it user-friendly with color-coded alerts, logs GPS+depth tracks to SQLite, and supports a simulation mode for hardware-free development.

**Architecture:** Layered Flutter app. `core/services/` hosts `DepthSource` (abstract) with two implementations (`BluetoothService`, `SimulationService`), plus `NmeaParser`, `LocationService`, `DepthLogService`, `AlertEngine`. Riverpod providers wire services to UI. Three feature screens (`depth/`, `map/`, `settings/`) under a bottom-nav shell. All non-Bluetooth services are TDD-driven.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod 2.x, flutter_blue_plus, flutter_bluetooth_serial, flutter_map, geolocator, sqflite, vibration, audioplayers.

**Spec:** [`docs/superpowers/specs/2026-05-03-jetski-design.md`](../specs/2026-05-03-jetski-design.md)

---

## File Structure

```
projet jetski/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── models/
│   │   │   ├── depth_sample.dart
│   │   │   └── nmea_sentence.dart
│   │   ├── services/
│   │   │   ├── depth_source.dart
│   │   │   ├── nmea_parser.dart
│   │   │   ├── simulation_service.dart
│   │   │   ├── bluetooth_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── depth_log_service.dart
│   │   │   ├── depth_logger.dart
│   │   │   ├── notification_service.dart
│   │   │   └── alert_engine.dart
│   │   ├── providers/
│   │   │   └── app_providers.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── depth/
│   │   │   ├── depth_screen.dart
│   │   │   └── depth_display.dart
│   │   ├── map/
│   │   │   ├── map_screen.dart
│   │   │   └── track_layer.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── threshold_slider.dart
│   └── shell/
│       └── home_shell.dart
├── test/
│   ├── unit/
│   │   ├── depth_sample_test.dart
│   │   ├── nmea_sentence_test.dart
│   │   ├── nmea_parser_test.dart
│   │   ├── simulation_service_test.dart
│   │   ├── alert_engine_test.dart
│   │   ├── notification_service_test.dart
│   │   ├── depth_logger_test.dart
│   │   ├── track_color_test.dart
│   │   └── depth_log_service_test.dart
│   ├── widget/
│   │   ├── depth_screen_test.dart
│   │   └── settings_screen_test.dart
│   └── integration/
│       └── pipeline_test.dart
└── assets/
    └── sounds/
        ├── warning.wav
        └── danger.wav
```

---

## Task 1: Bootstrap Flutter project & dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart` (placeholder)
- Create: `analysis_options.yaml`

- [ ] **Step 1: Run `flutter create` in the project folder**

```bash
cd "/c/Users/finan/Desktop/projet jetski"
flutter create --project-name projet_jetski --org com.finan.jetski --platforms ios,android .
```

Expected: scaffold generated, `pubspec.yaml` and `lib/main.dart` written.

- [ ] **Step 2: Replace `pubspec.yaml` content**

```yaml
name: projet_jetski
description: Real-time depth display & shallow-water alerts for jetskis
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  flutter_riverpod: ^2.5.1
  flutter_blue_plus: ^1.32.0
  flutter_bluetooth_serial: ^0.4.0
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  sqflite: ^2.3.0
  path: ^1.9.0
  vibration: ^2.0.0
  audioplayers: ^6.0.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3
  sqflite_common_ffi: ^2.3.0

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
```

- [ ] **Step 3: Run `flutter pub get`**

```bash
flutter pub get
```

Expected: `Got dependencies!` printed; `pubspec.lock` created.

- [ ] **Step 4: Replace `lib/main.dart` with placeholder**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: _BootstrapApp()));
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Projet Jetski — bootstrap'))),
    );
  }
}
```

- [ ] **Step 5: Verify the project compiles**

```bash
flutter analyze
```

Expected: `No issues found!` (or zero errors).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart analysis_options.yaml android/ ios/ .metadata
git commit -m "feat: bootstrap Flutter project & dependencies"
```

---

## Task 2: DepthSample model

**Files:**
- Create: `lib/core/models/depth_sample.dart`
- Test: `test/unit/depth_sample_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/depth_sample_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';

void main() {
  group('DepthSample', () {
    test('constructs with required fields', () {
      final s = DepthSample(
        timestamp: DateTime.utc(2026, 5, 3, 12, 0, 0),
        depthMeters: 3.2,
        latitude: 46.81,
        longitude: -71.21,
        source: SampleSource.simulated,
      );
      expect(s.depthMeters, 3.2);
      expect(s.source, SampleSource.simulated);
      expect(s.latitude, 46.81);
    });

    test('latitude and longitude are optional (sensor-only sample)', () {
      final s = DepthSample(
        timestamp: DateTime.utc(2026, 5, 3),
        depthMeters: 1.5,
        source: SampleSource.real,
      );
      expect(s.latitude, isNull);
      expect(s.longitude, isNull);
    });

    test('two samples with same fields are equal', () {
      final t = DateTime.utc(2026, 5, 3);
      final a = DepthSample(timestamp: t, depthMeters: 2.0, source: SampleSource.real);
      final b = DepthSample(timestamp: t, depthMeters: 2.0, source: SampleSource.real);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toMap and fromMap roundtrip', () {
      final t = DateTime.utc(2026, 5, 3, 14, 30);
      final original = DepthSample(
        timestamp: t,
        depthMeters: 2.7,
        latitude: 46.81,
        longitude: -71.21,
        source: SampleSource.real,
      );
      final restored = DepthSample.fromMap(original.toMap());
      expect(restored, equals(original));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/depth_sample_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:projet_jetski/core/models/depth_sample.dart'`.

- [ ] **Step 3: Write the model**

`lib/core/models/depth_sample.dart`:

```dart
enum SampleSource { real, simulated }

class DepthSample {
  final DateTime timestamp;
  final double depthMeters;
  final double? latitude;
  final double? longitude;
  final SampleSource source;

  const DepthSample({
    required this.timestamp,
    required this.depthMeters,
    required this.source,
    this.latitude,
    this.longitude,
  });

  Map<String, Object?> toMap() => {
        'timestamp_ms': timestamp.toUtc().millisecondsSinceEpoch,
        'depth_m': depthMeters,
        'lat': latitude,
        'lng': longitude,
        'source': source.name,
      };

  factory DepthSample.fromMap(Map<String, Object?> m) => DepthSample(
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(m['timestamp_ms']! as int, isUtc: true),
        depthMeters: (m['depth_m']! as num).toDouble(),
        latitude: (m['lat'] as num?)?.toDouble(),
        longitude: (m['lng'] as num?)?.toDouble(),
        source: SampleSource.values.byName(m['source']! as String),
      );

  @override
  bool operator ==(Object other) =>
      other is DepthSample &&
      timestamp == other.timestamp &&
      depthMeters == other.depthMeters &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      source == other.source;

  @override
  int get hashCode =>
      Object.hash(timestamp, depthMeters, latitude, longitude, source);
}
```

- [ ] **Step 4: Run test, verify it passes**

```bash
flutter test test/unit/depth_sample_test.dart
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/depth_sample.dart test/unit/depth_sample_test.dart
git commit -m "feat: add DepthSample model with persistence map"
```

---

## Task 3: NmeaSentence model + checksum

**Files:**
- Create: `lib/core/models/nmea_sentence.dart`
- Test: `test/unit/nmea_sentence_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/nmea_sentence_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/nmea_sentence.dart';

void main() {
  group('NmeaSentence.tryParse', () {
    test('parses a valid $DPT sentence', () {
      // Checksum of 'SDDPT,3.5,0.5' is 0x54
      final s = NmeaSentence.tryParse(r'$SDDPT,3.5,0.5*54');
      expect(s, isNotNull);
      expect(s!.talker, 'SD');
      expect(s.type, 'DPT');
      expect(s.fields, ['3.5', '0.5']);
    });

    test('returns null on bad checksum', () {
      final s = NmeaSentence.tryParse(r'$SDDPT,3.5,0.5*FF');
      expect(s, isNull);
    });

    test('returns null when missing $ prefix', () {
      expect(NmeaSentence.tryParse('SDDPT,3.5,0.5*54'), isNull);
    });

    test('returns null when missing checksum delimiter', () {
      expect(NmeaSentence.tryParse(r'$SDDPT,3.5,0.5'), isNull);
    });

    test('returns null on empty input', () {
      expect(NmeaSentence.tryParse(''), isNull);
    });

    test('handles trailing CR/LF', () {
      final s = NmeaSentence.tryParse('\$SDDPT,3.5,0.5*54\r\n');
      expect(s, isNotNull);
      expect(s!.type, 'DPT');
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/nmea_sentence_test.dart
```

Expected: FAIL — `nmea_sentence.dart` not found.

- [ ] **Step 3: Write the model**

`lib/core/models/nmea_sentence.dart`:

```dart
class NmeaSentence {
  final String talker;
  final String type;
  final List<String> fields;

  const NmeaSentence({
    required this.talker,
    required this.type,
    required this.fields,
  });

  static NmeaSentence? tryParse(String raw) {
    final line = raw.trim();
    if (line.isEmpty || !line.startsWith(r'$')) return null;
    final star = line.indexOf('*');
    if (star == -1 || star + 3 > line.length) return null;

    final body = line.substring(1, star);
    final checksumHex = line.substring(star + 1, star + 3).toUpperCase();
    final expected = int.tryParse(checksumHex, radix: 16);
    if (expected == null) return null;

    int xor = 0;
    for (final c in body.codeUnits) {
      xor ^= c;
    }
    if (xor != expected) return null;

    final parts = body.split(',');
    if (parts.isEmpty || parts.first.length < 5) return null;
    final header = parts.first;
    final talker = header.substring(0, 2);
    final type = header.substring(2);
    final fields = parts.sublist(1);
    return NmeaSentence(talker: talker, type: type, fields: fields);
  }
}
```

- [ ] **Step 4: Run test, verify it passes**

```bash
flutter test test/unit/nmea_sentence_test.dart
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/nmea_sentence.dart test/unit/nmea_sentence_test.dart
git commit -m "feat: parse and validate NMEA 0183 sentences with checksum"
```

---

## Task 4: NmeaParser — extract depth from $DPT and $DBT

**Files:**
- Create: `lib/core/services/nmea_parser.dart`
- Test: `test/unit/nmea_parser_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/nmea_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/nmea_parser.dart';

void main() {
  group('NmeaParser.depthMeters', () {
    test('reads metres from $DPT', () {
      // $SDDPT,3.5,0.5*54 — depth 3.5 m, offset 0.5 m
      expect(NmeaParser.depthMeters(r'$SDDPT,3.5,0.5*54'), 3.5);
    });

    test('reads metres from $DBT (uses M field, not feet)', () {
      // Body "SDDBT,11.5,f,3.50,M,1.91,F" XOR = 0x3C
      expect(NmeaParser.depthMeters(r'$SDDBT,11.5,f,3.50,M,1.91,F*3C'), 3.50);
    });

    test('returns null on $GLL (irrelevant sentence)', () {
      // GLL is a position sentence, not a depth one — depthMeters must return null
      expect(NmeaParser.depthMeters(r'$GPGLL,4807.038,N,01131.000,E,123519,A*25'), isNull);
    });

    test('returns null on garbage', () {
      expect(NmeaParser.depthMeters('not a sentence'), isNull);
    });

    test('returns null when depth field is empty', () {
      // Checksum of 'SDDPT,,0.5' = 0x7C — empty depth field
      expect(NmeaParser.depthMeters(r'$SDDPT,,0.5*7C'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/nmea_parser_test.dart
```

Expected: FAIL — `nmea_parser.dart` not found.

- [ ] **Step 3: Write the parser**

`lib/core/services/nmea_parser.dart`:

```dart
import '../models/nmea_sentence.dart';

class NmeaParser {
  /// Returns the depth in metres from a single NMEA line, or null if the line
  /// is not a depth sentence or is invalid.
  static double? depthMeters(String line) {
    final s = NmeaSentence.tryParse(line);
    if (s == null) return null;

    if (s.type == 'DPT') {
      // Field 0 = depth in metres (relative to transducer)
      if (s.fields.isEmpty || s.fields[0].isEmpty) return null;
      return double.tryParse(s.fields[0]);
    }

    if (s.type == 'DBT') {
      // Format: feet, f, metres, M, fathoms, F
      // Pick the metre value (index 2) when its unit indicator (index 3) is 'M'.
      if (s.fields.length < 4) return null;
      if (s.fields[3].toUpperCase() != 'M') return null;
      if (s.fields[2].isEmpty) return null;
      return double.tryParse(s.fields[2]);
    }

    return null;
  }
}
```

- [ ] **Step 4: Run test, verify all 5 pass**

```bash
flutter test test/unit/nmea_parser_test.dart
```

Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/nmea_parser.dart test/unit/nmea_parser_test.dart
git commit -m "feat: extract depth in metres from \$DPT and \$DBT"
```

---

## Task 5: DepthSource interface + SimulationService

**Files:**
- Create: `lib/core/services/depth_source.dart`
- Create: `lib/core/services/simulation_service.dart`
- Test: `test/unit/simulation_service_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/simulation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/depth_source.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';

void main() {
  group('SimulationService', () {
    test('emits a stream of depths for the "approach" scenario', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      final samples = await svc.depthMeters.take(5).toList();
      expect(samples, hasLength(5));
      // Approach: starts deep, gets shallower over time.
      expect(samples.first, greaterThan(samples.last));
      await svc.stop();
    });

    test('manual scenario emits the value set via setManualDepth', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.manual,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      svc.setManualDepth(0.7);
      final v = await svc.depthMeters.first;
      expect(v, 0.7);
      await svc.stop();
    });

    test('implements DepthSource', () {
      final svc = SimulationService(scenario: SimulationScenario.approach);
      expect(svc, isA<DepthSource>());
    });

    test('cannot start twice', () async {
      final svc = SimulationService(
        scenario: SimulationScenario.approach,
        tickInterval: const Duration(milliseconds: 1),
      );
      await svc.start();
      expect(() => svc.start(), throwsStateError);
      await svc.stop();
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/simulation_service_test.dart
```

Expected: FAIL — files don't exist yet.

- [ ] **Step 3: Write the abstract `DepthSource`**

`lib/core/services/depth_source.dart`:

```dart
abstract class DepthSource {
  /// Stream of depth readings in metres. Emits at the source's natural rate
  /// (≥ 1 Hz for real sensors and the simulation).
  Stream<double> get depthMeters;

  /// Begin emitting. Throws StateError if already started.
  Future<void> start();

  /// Stop emitting and release resources.
  Future<void> stop();
}
```

- [ ] **Step 4: Write the simulation**

`lib/core/services/simulation_service.dart`:

```dart
import 'dart:async';
import 'dart:math';
import 'depth_source.dart';

enum SimulationScenario { approach, suddenDanger, unstable, manual }

class SimulationService implements DepthSource {
  final SimulationScenario scenario;
  final Duration tickInterval;
  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  int _tick = 0;
  double _manual = 2.0;
  final _rand = Random(42);

  SimulationService({
    required this.scenario,
    this.tickInterval = const Duration(milliseconds: 200),
  });

  @override
  Stream<double> get depthMeters => _controller.stream;

  void setManualDepth(double v) => _manual = v;

  @override
  Future<void> start() async {
    if (_timer != null) {
      throw StateError('SimulationService already started');
    }
    _tick = 0;
    _timer = Timer.periodic(tickInterval, (_) => _emit());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  void _emit() {
    final v = switch (scenario) {
      SimulationScenario.approach => _approach(_tick),
      SimulationScenario.suddenDanger => _sudden(_tick),
      SimulationScenario.unstable => _unstable(_tick),
      SimulationScenario.manual => _manual,
    };
    _controller.add(v);
    _tick++;
  }

  double _approach(int t) {
    // Start at 5 m, lose 0.05 m per tick, floor at 0.1 m.
    return max(0.1, 5.0 - t * 0.05);
  }

  double _sudden(int t) {
    // 3 m for the first 30 ticks, then drop instantly to 0.3 m.
    return t < 30 ? 3.0 : 0.3;
  }

  double _unstable(int t) {
    // 2 m baseline + ±0.6 m noise.
    return 2.0 + (_rand.nextDouble() - 0.5) * 1.2;
  }
}
```

- [ ] **Step 5: Run test, verify all 4 pass**

```bash
flutter test test/unit/simulation_service_test.dart
```

Expected: All 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/depth_source.dart lib/core/services/simulation_service.dart test/unit/simulation_service_test.dart
git commit -m "feat: DepthSource interface + simulation with 4 scenarios"
```

---

## Task 6: AlertEngine — thresholds + hysteresis

**Files:**
- Create: `lib/core/services/alert_engine.dart`
- Test: `test/unit/alert_engine_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/alert_engine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';

void main() {
  group('AlertEngine', () {
    late AlertEngine engine;

    setUp(() {
      engine = AlertEngine(
        warningMeters: 1.0,
        dangerMeters: 0.5,
        hysteresisMeters: 0.3,
      );
    });

    test('starts in safe level', () {
      expect(engine.level, AlertLevel.safe);
    });

    test('transitions to warning when depth drops below warning threshold', () {
      expect(engine.update(0.9), AlertLevel.warning);
      expect(engine.level, AlertLevel.warning);
    });

    test('transitions to danger when depth drops below danger threshold', () {
      engine.update(0.9);
      expect(engine.update(0.4), AlertLevel.danger);
    });

    test('hysteresis: warning does not clear at exactly the threshold', () {
      engine.update(0.9); // -> warning
      // Threshold + hysteresis is 1.0 + 0.3 = 1.3 m. 1.05 m must stay warning.
      expect(engine.update(1.05), AlertLevel.warning);
      // 1.31 m clears the warning.
      expect(engine.update(1.31), AlertLevel.safe);
    });

    test('hysteresis: danger only clears above 0.5 + 0.3 = 0.8 m', () {
      engine.update(0.4); // -> danger
      expect(engine.update(0.6), AlertLevel.danger);
      expect(engine.update(0.81), AlertLevel.warning);
    });

    test('emits onTransition only on level changes', () {
      final transitions = <AlertLevel>[];
      engine.onTransition = transitions.add;
      engine.update(2.0);  // safe (no change, no transition)
      engine.update(0.9);  // -> warning
      engine.update(0.85); // still warning
      engine.update(0.4);  // -> danger
      engine.update(0.45); // still danger
      engine.update(2.0);  // -> safe
      expect(transitions, [
        AlertLevel.warning,
        AlertLevel.danger,
        AlertLevel.safe,
      ]);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/alert_engine_test.dart
```

Expected: FAIL — `alert_engine.dart` not found.

- [ ] **Step 3: Write the engine**

`lib/core/services/alert_engine.dart`:

```dart
enum AlertLevel { safe, warning, danger }

typedef AlertTransitionCallback = void Function(AlertLevel newLevel);

class AlertEngine {
  final double warningMeters;
  final double dangerMeters;
  final double hysteresisMeters;
  AlertLevel _level = AlertLevel.safe;
  AlertTransitionCallback? onTransition;

  AlertEngine({
    required this.warningMeters,
    required this.dangerMeters,
    this.hysteresisMeters = 0.3,
  }) : assert(dangerMeters < warningMeters);

  AlertLevel get level => _level;

  /// Feed a new depth reading and return the resulting level.
  AlertLevel update(double depthMeters) {
    final next = _compute(depthMeters);
    if (next != _level) {
      _level = next;
      onTransition?.call(next);
    }
    return _level;
  }

  AlertLevel _compute(double d) {
    switch (_level) {
      case AlertLevel.safe:
        if (d <= dangerMeters) return AlertLevel.danger;
        if (d <= warningMeters) return AlertLevel.warning;
        return AlertLevel.safe;
      case AlertLevel.warning:
        if (d <= dangerMeters) return AlertLevel.danger;
        if (d > warningMeters + hysteresisMeters) return AlertLevel.safe;
        return AlertLevel.warning;
      case AlertLevel.danger:
        if (d > dangerMeters + hysteresisMeters) {
          // Step back up — could be still in warning band, or fully safe.
          if (d > warningMeters + hysteresisMeters) return AlertLevel.safe;
          return AlertLevel.warning;
        }
        return AlertLevel.danger;
    }
  }
}
```

- [ ] **Step 4: Run test, verify all 6 pass**

```bash
flutter test test/unit/alert_engine_test.dart
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/alert_engine.dart test/unit/alert_engine_test.dart
git commit -m "feat: alert engine with thresholds and hysteresis"
```

---

## Task 7: DepthLogService — SQLite persistence

**Files:**
- Create: `lib/core/services/depth_log_service.dart`
- Test: `test/unit/depth_log_service_test.dart`

- [ ] **Step 1: Write the failing test**

`test/unit/depth_log_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';
import 'package:projet_jetski/core/services/depth_log_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DepthLogService', () {
    late DepthLogService service;

    setUp(() async {
      service = DepthLogService();
      await service.openInMemory();
    });

    tearDown(() async {
      await service.close();
    });

    test('stores and reads back a sample', () async {
      final s = DepthSample(
        timestamp: DateTime.utc(2026, 5, 3, 12, 0, 0),
        depthMeters: 3.0,
        latitude: 46.81,
        longitude: -71.21,
        source: SampleSource.real,
      );
      await service.add(s);
      final all = await service.all();
      expect(all, hasLength(1));
      expect(all.first, equals(s));
    });

    test('orders samples by timestamp ascending', () async {
      final t0 = DateTime.utc(2026, 5, 3, 12, 0, 0);
      await service.add(DepthSample(timestamp: t0.add(const Duration(seconds: 2)), depthMeters: 2.0, source: SampleSource.real));
      await service.add(DepthSample(timestamp: t0, depthMeters: 3.0, source: SampleSource.real));
      await service.add(DepthSample(timestamp: t0.add(const Duration(seconds: 1)), depthMeters: 1.0, source: SampleSource.real));
      final all = await service.all();
      expect(all.map((s) => s.depthMeters), [3.0, 1.0, 2.0]);
    });

    test('range query filters by timestamp', () async {
      final t0 = DateTime.utc(2026, 5, 3);
      for (var i = 0; i < 5; i++) {
        await service.add(DepthSample(
          timestamp: t0.add(Duration(seconds: i)),
          depthMeters: i.toDouble(),
          source: SampleSource.real,
        ));
      }
      final mid = await service.range(
        from: t0.add(const Duration(seconds: 1)),
        to: t0.add(const Duration(seconds: 3)),
      );
      expect(mid.map((s) => s.depthMeters), [1.0, 2.0, 3.0]);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/depth_log_service_test.dart
```

Expected: FAIL — `depth_log_service.dart` not found.

- [ ] **Step 3: Write the service**

`lib/core/services/depth_log_service.dart`:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/depth_sample.dart';

class DepthLogService {
  Database? _db;

  Future<void> open() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'jetski_depth_log.db'),
      version: 1,
      onCreate: _migrate,
    );
  }

  /// In-memory variant for tests.
  Future<void> openInMemory() async {
    _db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: _migrate);
  }

  Future<void> _migrate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE depth_samples (
        timestamp_ms INTEGER NOT NULL,
        depth_m      REAL    NOT NULL,
        lat          REAL,
        lng          REAL,
        source       TEXT    NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_depth_samples_timestamp ON depth_samples(timestamp_ms)',
    );
  }

  Future<void> add(DepthSample s) async {
    await _requireDb().insert('depth_samples', s.toMap());
  }

  Future<List<DepthSample>> all() async {
    final rows = await _requireDb()
        .query('depth_samples', orderBy: 'timestamp_ms ASC');
    return rows.map(DepthSample.fromMap).toList();
  }

  Future<List<DepthSample>> range({required DateTime from, required DateTime to}) async {
    final rows = await _requireDb().query(
      'depth_samples',
      where: 'timestamp_ms >= ? AND timestamp_ms <= ?',
      whereArgs: [
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp_ms ASC',
    );
    return rows.map(DepthSample.fromMap).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Database _requireDb() {
    final db = _db;
    if (db == null) throw StateError('DepthLogService not opened');
    return db;
  }
}
```

- [ ] **Step 4: Run test, verify all 3 pass**

```bash
flutter test test/unit/depth_log_service_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/depth_log_service.dart test/unit/depth_log_service_test.dart
git commit -m "feat: SQLite-backed depth log with range queries"
```

---

## Task 8: LocationService — GPS wrapper

**Files:**
- Create: `lib/core/services/location_service.dart`

This service is a thin wrapper over `geolocator`. The package itself is platform-channel-based and not unit-testable without complex mocks. We test it indirectly through the integration test in Task 16.

- [ ] **Step 1: Write the service**

`lib/core/services/location_service.dart`:

```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position>? _stream;

  /// Request permission and start streaming positions. Returns null if the
  /// user denies permission.
  Future<Stream<Position>?> start() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    _stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    );
    return _stream;
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/core/services/location_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/location_service.dart
git commit -m "feat: LocationService wrapping geolocator"
```

---

## Task 9: BluetoothService — real NMEA-over-SPP

**Files:**
- Create: `lib/core/services/bluetooth_service.dart`

Bluetooth depth sounders most commonly emit NMEA 0183 over Bluetooth Classic SPP. We use `flutter_bluetooth_serial` for that, decode bytes line-by-line, hand each line to `NmeaParser.depthMeters`. Untestable without hardware — covered by manual test post-launch.

- [ ] **Step 1: Write the service**

`lib/core/services/bluetooth_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'depth_source.dart';
import 'nmea_parser.dart';

class BluetoothService implements DepthSource {
  final String address; // MAC address chosen by user
  BluetoothConnection? _connection;
  final _controller = StreamController<double>.broadcast();
  String _buffer = '';

  BluetoothService(this.address);

  @override
  Stream<double> get depthMeters => _controller.stream;

  @override
  Future<void> start() async {
    if (_connection != null) {
      throw StateError('BluetoothService already started');
    }
    _connection = await BluetoothConnection.toAddress(address);
    _connection!.input!.listen(_onBytes, onDone: stop);
  }

  void _onBytes(List<int> bytes) {
    _buffer += utf8.decode(bytes, allowMalformed: true);
    while (true) {
      final nl = _buffer.indexOf('\n');
      if (nl == -1) break;
      final line = _buffer.substring(0, nl);
      _buffer = _buffer.substring(nl + 1);
      final d = NmeaParser.depthMeters(line);
      if (d != null) _controller.add(d);
    }
  }

  /// List all currently bonded Bluetooth devices.
  static Future<List<BluetoothDevice>> bondedDevices() {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  @override
  Future<void> stop() async {
    await _connection?.close();
    _connection = null;
    _buffer = '';
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/core/services/bluetooth_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/bluetooth_service.dart
git commit -m "feat: BluetoothService streaming depth from NMEA over SPP"
```

---

## Task 10: Theme + Riverpod providers + threshold persistence

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/providers/app_providers.dart`

- [ ] **Step 1: Write the theme**

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const safeColor = Color(0xFF1A4D2E);
  static const warningColor = Color(0xFFE6A23C);
  static const dangerColor = Color(0xFFD63031);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4D2E)),
    );
  }
}
```

- [ ] **Step 2: Write the providers**

`lib/core/providers/app_providers.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
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
```

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/core/theme/app_theme.dart lib/core/providers/app_providers.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/core/providers/app_providers.dart
git commit -m "feat: theme + Riverpod providers wiring services to thresholds"
```

---

## Task 11: DepthScreen widget

**Files:**
- Create: `lib/features/depth/depth_screen.dart`
- Create: `lib/features/depth/depth_display.dart`
- Test: `test/widget/depth_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

`test/widget/depth_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/theme/app_theme.dart';
import 'package:projet_jetski/features/depth/depth_display.dart';

void main() {
  testWidgets('DepthDisplay shows depth in metres with safe color when level is safe',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DepthDisplay(depth: 3.2, level: AlertLevel.safe),
          ),
        ),
      ),
    );
    expect(find.text('3.2'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    final container = tester.widget<Container>(
      find.byKey(const Key('depth-bg')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTheme.safeColor);
  });

  testWidgets('shows danger color when level is danger', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DepthDisplay(depth: 0.3, level: AlertLevel.danger),
          ),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const Key('depth-bg')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTheme.dangerColor);
  });

  testWidgets('shows --.- when depth is null', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DepthDisplay(depth: null, level: AlertLevel.safe),
          ),
        ),
      ),
    );
    expect(find.text('--.-'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/widget/depth_screen_test.dart
```

Expected: FAIL — `depth_display.dart` not found.

- [ ] **Step 3: Write the display widget**

`lib/features/depth/depth_display.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/services/alert_engine.dart';
import '../../core/theme/app_theme.dart';

class DepthDisplay extends StatelessWidget {
  final double? depth;
  final AlertLevel level;

  const DepthDisplay({super.key, required this.depth, required this.level});

  @override
  Widget build(BuildContext context) {
    final bg = switch (level) {
      AlertLevel.safe => AppTheme.safeColor,
      AlertLevel.warning => AppTheme.warningColor,
      AlertLevel.danger => AppTheme.dangerColor,
    };
    final text = depth == null ? '--.-' : depth!.toStringAsFixed(1);
    return Container(
      key: const Key('depth-bg'),
      decoration: BoxDecoration(color: bg),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profondeur',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const Padding(
                padding: EdgeInsets.only(bottom: 18.0, left: 8),
                child: Text('m',
                    style: TextStyle(color: Colors.white70, fontSize: 28)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Write the screen**

`lib/features/depth/depth_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'depth_display.dart';

class DepthScreen extends ConsumerWidget {
  const DepthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depth = ref.watch(depthStreamProvider).valueOrNull;
    final level = ref.watch(alertLevelProvider).valueOrNull ?? AlertLevel.safe;
    return Scaffold(
      body: SafeArea(child: DepthDisplay(depth: depth, level: level)),
    );
  }
}
```

The `DepthScreen` import block must include `package:projet_jetski/core/services/alert_engine.dart` for `AlertLevel`.
```

- [ ] **Step 5: Run test, verify all 3 pass**

```bash
flutter test test/widget/depth_screen_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/depth/ test/widget/depth_screen_test.dart
git commit -m "feat: DepthScreen widget with color-coded background"
```

---

## Task 12: SettingsScreen with threshold sliders

**Files:**
- Create: `lib/features/settings/settings_screen.dart`
- Create: `lib/features/settings/threshold_slider.dart`
- Test: `test/widget/settings_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

`test/widget/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows two sliders labelled warning and danger', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Seuil avertissement'), findsOneWidget);
    expect(find.textContaining('Seuil danger'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
  });

  testWidgets('default labels show 1.0 m and 0.5 m', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.0 m'), findsOneWidget);
    expect(find.text('0.5 m'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/widget/settings_screen_test.dart
```

Expected: FAIL — `settings_screen.dart` not found.

- [ ] **Step 3: Write the slider widget**

`lib/features/settings/threshold_slider.dart`:

```dart
import 'package:flutter/material.dart';

class ThresholdSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const ThresholdSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0.1,
    this.max = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Text('${value.toStringAsFixed(1)} m'),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Write the screen**

`lib/features/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'threshold_slider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final th = ref.watch(thresholdsProvider);
    final notifier = ref.read(thresholdsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ThresholdSlider(
            label: 'Seuil avertissement',
            value: th.warningMeters,
            min: th.dangerMeters + 0.1,
            max: 5.0,
            onChanged: notifier.setWarning,
          ),
          ThresholdSlider(
            label: 'Seuil danger',
            value: th.dangerMeters,
            min: 0.1,
            max: th.warningMeters - 0.1,
            onChanged: notifier.setDanger,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test, verify both pass**

```bash
flutter test test/widget/settings_screen_test.dart
```

Expected: Both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/ test/widget/settings_screen_test.dart
git commit -m "feat: SettingsScreen with persisted threshold sliders"
```

---

## Task 13: MapScreen with track layer

**Files:**
- Create: `lib/features/map/map_screen.dart`
- Create: `lib/features/map/track_layer.dart`

`flutter_map` widgets render tiles asynchronously and are not meaningfully testable in isolation — visual verification is via the on-device run during integration. We write a small unit test for the segment-coloring helper inside `track_layer.dart`.

- [ ] **Step 1: Write the failing helper test**

Append to `test/unit/alert_engine_test.dart` is wrong — make a new file.

`test/unit/track_color_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/theme/app_theme.dart';
import 'package:projet_jetski/features/map/track_layer.dart';

void main() {
  group('colorForDepth', () {
    test('safe band -> safeColor', () {
      expect(colorForDepth(2.0, warning: 1.0, danger: 0.5), AppTheme.safeColor);
    });
    test('warning band -> warningColor', () {
      expect(colorForDepth(0.8, warning: 1.0, danger: 0.5), AppTheme.warningColor);
    });
    test('danger band -> dangerColor', () {
      expect(colorForDepth(0.3, warning: 1.0, danger: 0.5), AppTheme.dangerColor);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/track_color_test.dart
```

Expected: FAIL — `track_layer.dart` not found.

- [ ] **Step 3: Write the track layer**

`lib/features/map/track_layer.dart`:

```dart
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
```

- [ ] **Step 4: Write the screen**

`lib/features/map/map_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(46.81, -71.21), // Québec City default
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.finan.jetski',
          ),
        ],
      ),
    );
  }
}
```

(The `trackPolylineLayer` helper is wired in by integration test once `DepthLogService` exposes a stream — out of scope for v0.1 MVP screen.)

- [ ] **Step 5: Run test, verify it passes**

```bash
flutter test test/unit/track_color_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/map/ test/unit/track_color_test.dart
git commit -m "feat: MapScreen with OpenStreetMap tiles + track color helper"
```

---

## Task 14: HomeShell with bottom navigation

**Files:**
- Create: `lib/shell/home_shell.dart`

- [ ] **Step 1: Write the shell**

`lib/shell/home_shell.dart`:

```dart
import 'package:flutter/material.dart';
import '../features/depth/depth_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _screens = const [DepthScreen(), MapScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water), label: 'Profondeur'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Carte'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/shell/home_shell.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shell/home_shell.dart
git commit -m "feat: HomeShell with bottom navigation between three screens"
```

---

## Task 15: Wire app — main.dart + app.dart

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shell/home_shell.dart';

class JetskiApp extends StatelessWidget {
  const JetskiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Jetski',
      theme: AppTheme.light(),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: JetskiApp()));
}
```

- [ ] **Step 3: Verify the app builds**

```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat: wire app entry point and root widget"
```

---

## Task 16: Integration test — full simulation pipeline

**Files:**
- Create: `test/integration/pipeline_test.dart`

- [ ] **Step 1: Write the integration test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/services/depth_source.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('simulation -> depthStream -> alertLevel transitions to danger', () async {
    final container = ProviderContainer(overrides: [
      depthSourceProvider.overrideWith((ref) {
        final s = SimulationService(
          scenario: SimulationScenario.suddenDanger,
          tickInterval: const Duration(milliseconds: 5),
        );
        return s;
      }),
    ]);
    addTearDown(container.dispose);

    // Subscribe to the depth stream so the provider actually starts.
    final sub = container.listen(depthStreamProvider, (_, __) {});
    addTearDown(sub.close);

    // Wait until ~40 ticks elapse so we cross the suddenDanger transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final level = container.read(alertLevelProvider).valueOrNull;
    expect(level, AlertLevel.danger);
  });
}
```

- [ ] **Step 2: Run the integration test**

```bash
flutter test test/integration/pipeline_test.dart
```

Expected: PASS — the level reaches `AlertLevel.danger` once the simulation drops from 3.0 m to 0.3 m at tick 30.

- [ ] **Step 3: Run the full suite**

```bash
flutter test
```

Expected: ALL tests PASS (unit + widget + integration).

- [ ] **Step 4: Commit**

```bash
git add test/integration/pipeline_test.dart
git commit -m "test: end-to-end simulation pipeline triggers danger alert"
```

---

## Task 17: Sound assets + permissions + README

**Files:**
- Create: `assets/sounds/warning.wav`
- Create: `assets/sounds/danger.wav`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `README.md`

- [ ] **Step 1: Generate placeholder sound assets**

The MVP can ship with two short generated tones. Use Python or `sox` if available, or just commit a placeholder text file we replace later.

```bash
cd "/c/Users/finan/Desktop/projet jetski"
mkdir -p assets/sounds
python -c "
import wave, struct, math
def beep(path, freq, dur=0.4, sr=22050):
    with wave.open(path,'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        for i in range(int(dur*sr)):
            v = int(0.5 * 32767 * math.sin(2*math.pi*freq*i/sr))
            w.writeframes(struct.pack('<h', v))
beep('assets/sounds/warning.wav', 880, 0.4)
beep('assets/sounds/danger.wav', 1320, 0.6)
"
```

If Python is unavailable, skip this step — the audio playback step in v1 is a stretch goal and the alert still vibrates without a sound file.

- [ ] **Step 2: Add Android permissions**

Edit `android/app/src/main/AndroidManifest.xml`. Inside `<manifest>`, before `<application>`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.VIBRATE" />
```

- [ ] **Step 3: Add iOS permission descriptions**

Edit `ios/Runner/Info.plist`. Inside the top-level `<dict>`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connexion au sondeur de profondeur du jetski</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Connexion au sondeur de profondeur du jetski</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pour afficher votre trace GPS sur la carte</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Pour enregistrer votre trace même quand l'écran est verrouillé</string>
```

- [ ] **Step 4: Write README.md**

```markdown
# Projet Jetski

Application Flutter (iOS + Android) qui aide les propriétaires et locataires de
jetski à éviter les dommages en eau peu profonde, en lisant la profondeur en
temps réel depuis un sondeur Bluetooth NMEA 0183 et en affichant l'information
de manière user-friendly avec alertes sonores et visuelles.

## Documentation

- [Spec de design](docs/superpowers/specs/2026-05-03-jetski-design.md)
- [Plan d'implémentation](docs/superpowers/plans/2026-05-03-jetski-app.md)

## Démarrage

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

## Mode simulation

Pas besoin de sondeur pour développer ou démontrer l'app : le mode simulation
émet un flux de profondeurs fake selon 4 scénarios (approche progressive,
entrée brusque en danger, lecture instable, manuel).
```

- [ ] **Step 5: Verify everything still passes**

```bash
flutter analyze && flutter test
```

Expected: No issues, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add assets/ android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist README.md
git commit -m "feat: sound assets, OS permissions, and README"
```

---

## Task 18: NotificationService — vibration + audio wired to alert transitions

**Files:**
- Create: `lib/core/services/notification_service.dart`
- Test: `test/unit/notification_service_test.dart`
- Modify: `lib/core/providers/app_providers.dart`

The `AlertEngine` already exposes an `onTransition` callback. We build a thin service that consumes a stream of `AlertLevel` values and triggers vibration + sound on each transition. Tests use a fake vibration & audio backend so they run without device.

- [ ] **Step 1: Write the failing test**

`test/unit/notification_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/services/notification_service.dart';

class FakeBackend implements NotificationBackend {
  final calls = <String>[];
  @override
  Future<void> vibratePattern(List<int> pattern) async {
    calls.add('vibrate:${pattern.join(",")}');
  }
  @override
  Future<void> playWarning() async => calls.add('audio:warning');
  @override
  Future<void> playDanger() async => calls.add('audio:danger');
  @override
  Future<void> stopAudio() async => calls.add('audio:stop');
  @override
  Future<void> cancelVibration() async => calls.add('vibrate:cancel');
}

void main() {
  group('NotificationService', () {
    test('on warning transition: triggers warning vibration + sound', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.warning);
      expect(fake.calls, contains('audio:warning'));
      expect(fake.calls.any((c) => c.startsWith('vibrate:')), isTrue);
    });

    test('on danger transition: triggers danger vibration + sound', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.danger);
      expect(fake.calls, contains('audio:danger'));
    });

    test('on safe transition: cancels vibration and stops audio', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.safe);
      expect(fake.calls, contains('audio:stop'));
      expect(fake.calls, contains('vibrate:cancel'));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/notification_service_test.dart
```

Expected: FAIL — `notification_service.dart` not found.

- [ ] **Step 3: Write the service**

`lib/core/services/notification_service.dart`:

```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'alert_engine.dart';

abstract class NotificationBackend {
  Future<void> vibratePattern(List<int> pattern);
  Future<void> cancelVibration();
  Future<void> playWarning();
  Future<void> playDanger();
  Future<void> stopAudio();
}

class RealBackend implements NotificationBackend {
  final _player = AudioPlayer();

  @override
  Future<void> vibratePattern(List<int> pattern) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  @override
  Future<void> cancelVibration() async => Vibration.cancel();

  @override
  Future<void> playWarning() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/warning.wav'));
  }

  @override
  Future<void> playDanger() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/danger.wav'));
  }

  @override
  Future<void> stopAudio() async => _player.stop();
}

class NotificationService {
  final NotificationBackend backend;
  NotificationService(this.backend);

  /// Pattern: short single beep every 2s -> [delay, on, off, on, off]
  static const _warningPattern = [0, 200, 1800];
  /// Pattern: three short bursts every 1s
  static const _dangerPattern = [0, 150, 100, 150, 100, 150, 600];

  void handleTransition(AlertLevel level) {
    switch (level) {
      case AlertLevel.safe:
        backend.cancelVibration();
        backend.stopAudio();
      case AlertLevel.warning:
        backend.vibratePattern(_warningPattern);
        backend.playWarning();
      case AlertLevel.danger:
        backend.vibratePattern(_dangerPattern);
        backend.playDanger();
    }
  }
}
```

- [ ] **Step 4: Run tests, verify they pass**

```bash
flutter test test/unit/notification_service_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 5: Wire it into providers**

Append to `lib/core/providers/app_providers.dart`:

```dart
import '../services/notification_service.dart';

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
```

- [ ] **Step 6: Activate the notifier in `main.dart`**

Modify `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/app_providers.dart';

void main() {
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(alertNotifierProvider);
    return const JetskiApp();
  }
}
```

- [ ] **Step 7: Verify everything compiles and tests pass**

```bash
flutter analyze && flutter test
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/services/notification_service.dart test/unit/notification_service_test.dart lib/core/providers/app_providers.dart lib/main.dart
git commit -m "feat: vibration + audio notifications wired to alert transitions"
```

---

## Task 19: SettingsScreen — simulation toggle, scenario picker, units toggle

**Files:**
- Modify: `lib/core/providers/app_providers.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/widget/settings_screen_test.dart`

- [ ] **Step 1: Add unit + simulation state to providers**

Append to `lib/core/providers/app_providers.dart`:

```dart
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
```

Then **replace** the existing `depthSourceProvider` with:

```dart
final depthSourceProvider = Provider<DepthSource>((ref) {
  final sim = ref.watch(simSelectionProvider);
  // For v0.1 we always return a simulation source. v0.2 will add Bluetooth selection.
  return SimulationService(scenario: sim.scenario);
});
```

- [ ] **Step 2: Update the widget tests**

Replace `test/widget/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows two threshold sliders with default labels', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.text('1.0 m'), findsOneWidget);
    expect(find.text('0.5 m'), findsOneWidget);
  });

  testWidgets('shows simulation toggle and scenario picker', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Mode simulation'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('shows units toggle (m / ft)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Mètres'), findsOneWidget);
    expect(find.text('Pieds'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests to confirm they fail**

```bash
flutter test test/widget/settings_screen_test.dart
```

Expected: FAIL — new widgets not yet in the screen.

- [ ] **Step 4: Replace the SettingsScreen**

`lib/features/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/simulation_service.dart';
import 'threshold_slider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final th = ref.watch(thresholdsProvider);
    final thNotifier = ref.read(thresholdsProvider.notifier);
    final sim = ref.watch(simSelectionProvider);
    final simNotifier = ref.read(simSelectionProvider.notifier);
    final unit = ref.watch(unitProvider);
    final unitNotifier = ref.read(unitProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ThresholdSlider(
            label: 'Seuil avertissement',
            value: th.warningMeters,
            min: th.dangerMeters + 0.1,
            max: 5.0,
            onChanged: thNotifier.setWarning,
          ),
          ThresholdSlider(
            label: 'Seuil danger',
            value: th.dangerMeters,
            min: 0.1,
            max: th.warningMeters - 0.1,
            onChanged: thNotifier.setDanger,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Mode simulation'),
            subtitle: const Text('Émet une profondeur fake pour démo / dev'),
            value: sim.enabled,
            onChanged: simNotifier.setEnabled,
          ),
          if (sim.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Scénario : '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: sim.scenario.name,
                    items: SimulationScenario.values
                        .map((s) =>
                            DropdownMenuItem(value: s.name, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      simNotifier.setScenario(SimulationScenario.values.byName(v));
                    },
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Unité'),
            trailing: ToggleButtons(
              isSelected: [unit == DepthUnit.meters, unit == DepthUnit.feet],
              onPressed: (i) => unitNotifier
                  .setUnit(i == 0 ? DepthUnit.meters : DepthUnit.feet),
              children: const [Text('Mètres'), Text('Pieds')],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests, verify all 3 pass**

```bash
flutter test test/widget/settings_screen_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/providers/app_providers.dart lib/features/settings/settings_screen.dart test/widget/settings_screen_test.dart
git commit -m "feat: settings — simulation toggle, scenario picker, unit selector"
```

---

## Task 20: MapScreen — current GPS marker + persisted track polyline

**Files:**
- Modify: `lib/features/map/map_screen.dart`
- Modify: `lib/core/providers/app_providers.dart`

- [ ] **Step 1: Add a GPS position provider**

Append to `lib/core/providers/app_providers.dart`:

```dart
import 'package:geolocator/geolocator.dart';

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
```

Add the import at the top: `import '../models/depth_sample.dart';` if not present.

- [ ] **Step 2: Replace MapScreen**

`lib/features/map/map_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Carte')),
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
                width: 16, height: 16,
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
```

- [ ] **Step 3: Verify compilation**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/map/map_screen.dart lib/core/providers/app_providers.dart
git commit -m "feat: map shows live GPS marker + persisted depth track"
```

---

## Task 21: Wire depth logging — combine depth + GPS, persist to SQLite

**Files:**
- Create: `lib/core/services/depth_logger.dart`
- Test: `test/unit/depth_logger_test.dart`
- Modify: `lib/core/providers/app_providers.dart`

The logger consumes a depth stream and a position stream, builds `DepthSample`s, and writes them to `DepthLogService`. Bumps `depthLogVersionProvider` so the map re-reads samples.

- [ ] **Step 1: Write the failing test**

`test/unit/depth_logger_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';
import 'package:projet_jetski/core/services/depth_log_service.dart';
import 'package:projet_jetski/core/services/depth_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Pos {
  final double lat; final double lng;
  _Pos(this.lat, this.lng);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persists incoming depths combined with latest position', () async {
    final log = DepthLogService();
    await log.openInMemory();

    final depth = StreamController<double>();
    final pos = StreamController<_Pos?>();
    var bumped = 0;

    final logger = DepthLogger(
      logService: log,
      depthStream: depth.stream,
      positionStream: pos.stream.map((p) => p == null ? null : (p.lat, p.lng)),
      onCommit: () => bumped++,
      source: SampleSource.simulated,
    );
    logger.start();

    pos.add(_Pos(46.81, -71.21));
    depth.add(2.5);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    depth.add(0.4);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    await logger.stop();
    await depth.close();
    await pos.close();

    final all = await log.all();
    expect(all, hasLength(2));
    expect(all[0].depthMeters, 2.5);
    expect(all[0].latitude, 46.81);
    expect(all[1].depthMeters, 0.4);
    expect(bumped, 2);
    await log.close();
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
flutter test test/unit/depth_logger_test.dart
```

Expected: FAIL — `depth_logger.dart` not found.

- [ ] **Step 3: Write the logger**

`lib/core/services/depth_logger.dart`:

```dart
import 'dart:async';
import '../models/depth_sample.dart';
import 'depth_log_service.dart';

class DepthLogger {
  final DepthLogService logService;
  final Stream<double> depthStream;
  final Stream<(double, double)?> positionStream;
  final void Function() onCommit;
  final SampleSource source;
  StreamSubscription<double>? _depthSub;
  StreamSubscription<(double, double)?>? _posSub;
  (double, double)? _lastPos;

  DepthLogger({
    required this.logService,
    required this.depthStream,
    required this.positionStream,
    required this.onCommit,
    this.source = SampleSource.real,
  });

  void start() {
    _posSub = positionStream.listen((p) => _lastPos = p);
    _depthSub = depthStream.listen((d) async {
      final sample = DepthSample(
        timestamp: DateTime.now().toUtc(),
        depthMeters: d,
        latitude: _lastPos?.$1,
        longitude: _lastPos?.$2,
        source: source,
      );
      await logService.add(sample);
      onCommit();
    });
  }

  Future<void> stop() async {
    await _depthSub?.cancel();
    await _posSub?.cancel();
    _depthSub = null;
    _posSub = null;
  }
}
```

- [ ] **Step 4: Run test, verify it passes**

```bash
flutter test test/unit/depth_logger_test.dart
```

Expected: PASS.

- [ ] **Step 5: Wire it into providers**

Append to `lib/core/providers/app_providers.dart`:

```dart
import '../services/depth_logger.dart';

/// Activates depth logging when watched. Lifetime tied to ProviderScope.
final depthLoggerProvider = Provider<DepthLogger>((ref) {
  final log = ref.watch(depthLogServiceProvider);
  // Open the DB lazily; the logger awaits each add so a missing open() throws.
  unawaited(log.open());
  final depth = ref.watch(depthStreamProvider.stream);
  final pos = ref.watch(positionStreamProvider.stream).map(
        (p) => p == null ? null : (p.latitude, p.longitude),
      );
  final sim = ref.watch(simSelectionProvider).enabled;
  final logger = DepthLogger(
    logService: log,
    depthStream: depth,
    positionStream: pos,
    onCommit: () =>
        ref.read(depthLogVersionProvider.notifier).update((v) => v + 1),
    source: sim ? SampleSource.simulated : SampleSource.real,
  );
  logger.start();
  ref.onDispose(logger.stop);
  return logger;
});
```

- [ ] **Step 6: Activate logger in main bootstrap**

Modify `lib/main.dart`:

```dart
class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(alertNotifierProvider);
    ref.watch(depthLoggerProvider); // start logging
    return const JetskiApp();
  }
}
```

- [ ] **Step 7: Verify everything**

```bash
flutter analyze && flutter test
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/services/depth_logger.dart test/unit/depth_logger_test.dart lib/core/providers/app_providers.dart lib/main.dart
git commit -m "feat: persist depth + GPS samples to SQLite during sessions"
```

---

## Done

After completing Task 21:

- All 7 success criteria from the spec are met by automated tests except #1 in its real-Bluetooth form (requires hardware) and the live 30-minute device run.
- The simulation mode covers the same code paths and demonstrates every feature without hardware.
- Project is ready to `flutter run` on a connected Android device or iOS simulator.

Final manual verification (not automated):
1. `flutter run` on a real Android device.
2. Open the app → defaults to Profondeur screen (green, depth ticking down per `approach` scenario).
3. Wait until depth crosses 1.0 m → background turns yellow, vibration starts.
4. Wait until depth crosses 0.5 m → background turns red, vibration intensifies.
5. Switch to Carte tab → OSM tiles load, GPS marker appears (after granting location permission).
6. Switch to Réglages tab → move warning slider to 1.5 m → going back to Profondeur, the colour transitions kick in earlier.
