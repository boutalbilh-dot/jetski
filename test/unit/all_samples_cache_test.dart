import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/depth_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'allSamplesProvider returns growing snapshots without re-fetching old rows',
      () async {
    final svc = DepthLogService();
    await svc.openInMemory();
    addTearDown(svc.close);

    final start = DateTime.utc(2026, 5, 3, 12);

    final container = ProviderContainer(overrides: [
      depthLogServiceProvider.overrideWithValue(svc),
      sessionStartProvider.overrideWithValue(start),
    ]);
    addTearDown(container.dispose);

    // Seed two samples and let the provider load them.
    await svc.addAll([
      DepthSample(
        timestamp: start.add(const Duration(seconds: 1)),
        depthMeters: 1.0,
        source: SampleSource.real,
      ),
      DepthSample(
        timestamp: start.add(const Duration(seconds: 2)),
        depthMeters: 2.0,
        source: SampleSource.real,
      ),
    ]);
    container.read(depthLogVersionProvider.notifier).update((v) => v + 1);
    final first = await container.read(allSamplesProvider.future);
    expect(first.map((s) => s.depthMeters), [1.0, 2.0]);

    // Add one more sample and bump the version. The provider must return
    // a list that still contains the originals plus the new one — without
    // re-querying every row from the start of the session.
    await svc.add(DepthSample(
      timestamp: start.add(const Duration(seconds: 3)),
      depthMeters: 3.0,
      source: SampleSource.real,
    ));
    container.read(depthLogVersionProvider.notifier).update((v) => v + 1);
    container.invalidate(allSamplesProvider);
    final second = await container.read(allSamplesProvider.future);
    expect(second.map((s) => s.depthMeters), [1.0, 2.0, 3.0]);
  });
}
