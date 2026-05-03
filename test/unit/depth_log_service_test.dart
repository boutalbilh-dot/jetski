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
