import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';
import 'package:projet_jetski/core/services/depth_log_service.dart';
import 'package:projet_jetski/core/services/replay_depth_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<DepthLogService> seed(List<DepthSample> samples) async {
    final svc = DepthLogService();
    await svc.openInMemory();
    if (samples.isNotEmpty) await svc.addAll(samples);
    return svc;
  }

  test('emits stored samples in order at their original cadence', () async {
    final t0 = DateTime.utc(2026, 5, 3, 12, 0, 0);
    final samples = [
      DepthSample(timestamp: t0, depthMeters: 4.0, source: SampleSource.real),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 100)),
        depthMeters: 3.5,
        source: SampleSource.real,
      ),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 220)),
        depthMeters: 2.8,
        source: SampleSource.real,
      ),
    ];
    final svc = await seed(samples);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(days: 30),
      loop: false,
    );
    final emitted = <double>[];
    final sub = src.depthMeters.listen(emitted.add);

    await src.start();
    // Wait long enough for all 3 samples to fire (roughly the inter-sample sum)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(emitted, [4.0, 3.5, 2.8]);

    await sub.cancel();
    await src.stop();
    await svc.close();
  });

  test('emits nothing when there are no samples in the lookback window',
      () async {
    final svc = await seed(const []);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(hours: 1),
      loop: false,
    );
    final emitted = <double>[];
    final sub = src.depthMeters.listen(emitted.add);

    await src.start();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(emitted, isEmpty);

    await sub.cancel();
    await src.stop();
    await svc.close();
  });

  test('loops back to the first sample when loop=true', () async {
    final t0 = DateTime.utc(2026, 5, 3, 12, 0, 0);
    final samples = [
      DepthSample(timestamp: t0, depthMeters: 5.0, source: SampleSource.real),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 50)),
        depthMeters: 1.0,
        source: SampleSource.real,
      ),
    ];
    final svc = await seed(samples);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(days: 30),
      loop: true,
      loopGap: const Duration(milliseconds: 50),
    );
    final emitted = <double>[];
    final sub = src.depthMeters.listen(emitted.add);

    await src.start();
    // 2 samples (~50ms) + loopGap (50ms) + 2 samples (50ms) ≈ 150ms
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Should have at least 4 emissions (2 of the loop + 2 of the next pass).
    expect(emitted.length, greaterThanOrEqualTo(4));
    expect(emitted.take(2).toList(), [5.0, 1.0]);
    expect(emitted.skip(2).take(2).toList(), [5.0, 1.0]);

    await sub.cancel();
    await src.stop();
    await svc.close();
  });

  test('cannot start twice', () async {
    final svc = await seed(const []);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(hours: 1),
      loop: false,
    );
    await src.start();
    expect(src.start(), throwsStateError);
    await src.stop();
    await svc.close();
  });

  test('stop() closes the stream', () async {
    final t0 = DateTime.utc(2026, 5, 3, 12, 0, 0);
    final samples = [
      DepthSample(timestamp: t0, depthMeters: 2.0, source: SampleSource.real),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 500)),
        depthMeters: 1.5,
        source: SampleSource.real,
      ),
    ];
    final svc = await seed(samples);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(days: 30),
      loop: false,
    );
    final done = src.depthMeters.drain<void>();
    await src.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await src.stop();
    await done; // resolves only when the stream closes
    await svc.close();
  });

  test('ignores samples with source=simulated to avoid replay feedback loop',
      () async {
    final t0 = DateTime.utc(2026, 5, 3, 12, 0, 0);
    final samples = [
      DepthSample(timestamp: t0, depthMeters: 9.9, source: SampleSource.simulated),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 50)),
        depthMeters: 4.0,
        source: SampleSource.real,
      ),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 100)),
        depthMeters: 8.8,
        source: SampleSource.simulated,
      ),
      DepthSample(
        timestamp: t0.add(const Duration(milliseconds: 150)),
        depthMeters: 3.5,
        source: SampleSource.real,
      ),
    ];
    final svc = await seed(samples);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(days: 30),
      loop: false,
    );
    final emitted = <double>[];
    final sub = src.depthMeters.listen(emitted.add);

    await src.start();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(emitted, [4.0, 3.5]);
    expect(src.loadedSampleCount, 2);

    await sub.cancel();
    await src.stop();
    await svc.close();
  });

  test('implements DepthSource', () async {
    final svc = await seed(const []);
    final src = ReplayDepthSource(
      logService: svc,
      lookbackWindow: const Duration(hours: 1),
      loop: false,
    );
    // Compile-time guarantee via type system, plus runtime sanity.
    expect(src.depthMeters, isA<Stream<double>>());
    await svc.close();
  });
}
