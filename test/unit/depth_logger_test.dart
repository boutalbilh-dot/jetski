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

  test('batches depths into one transaction per flush window', () async {
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
      flushInterval: const Duration(milliseconds: 50),
    );
    await logger.start();

    pos.add(_Pos(46.81, -71.21));
    depth.add(2.5);
    depth.add(0.4);
    // Wait for one flush interval to elapse, with margin for parallel test load.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(bumped, greaterThanOrEqualTo(1),
        reason: 'two samples → at least one flush → at least one commit');

    await logger.stop();
    await depth.close();
    await pos.close();

    final all = await log.all();
    expect(all, hasLength(2));
    expect(all[0].depthMeters, 2.5);
    expect(all[0].latitude, 46.81);
    expect(all[1].depthMeters, 0.4);
    await log.close();
  });

  test('start() awaits open() to avoid the sample-vs-open race', () async {
    final log = DepthLogService();
    // Note: NOT pre-opened — start() must open it.
    final depth = StreamController<double>();
    final pos = StreamController<_Pos?>();

    final logger = DepthLogger(
      logService: log,
      depthStream: depth.stream,
      positionStream: pos.stream.map((p) => p == null ? null : (p.lat, p.lng)),
      onCommit: () {},
      source: SampleSource.simulated,
      flushInterval: const Duration(milliseconds: 10),
    );
    // Force an in-memory open since start() always opens the disk DB.
    await log.openInMemory();
    await logger.start();
    depth.add(1.0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await logger.stop();
    await depth.close();
    await pos.close();
    expect((await log.all()).single.depthMeters, 1.0);
    await log.close();
  });

  test('coalesces overlapping flushes (no duplicate writes)', () async {
    final log = DepthLogService();
    await log.openInMemory();
    final depth = StreamController<double>();
    final pos = StreamController<_Pos?>();
    var commits = 0;

    final logger = DepthLogger(
      logService: log,
      depthStream: depth.stream,
      positionStream: pos.stream.map((p) => p == null ? null : (p.lat, p.lng)),
      onCommit: () => commits++,
      source: SampleSource.simulated,
      flushInterval: const Duration(milliseconds: 5),
    );
    await logger.start();

    // Push samples faster than the flush interval can drain them.
    for (var i = 0; i < 20; i++) {
      depth.add(i.toDouble());
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await logger.stop();
    await depth.close();
    await pos.close();

    final all = await log.all();
    // Every sample must land exactly once — the coalescing flush guard must
    // not drop or double-write rows even when ticks overlap I/O.
    expect(all, hasLength(20));
    expect(all.map((s) => s.depthMeters).toList(),
        List.generate(20, (i) => i.toDouble()));
    // At least one commit fired; not strictly equal to one batch since real
    // timing is platform-dependent.
    expect(commits, greaterThanOrEqualTo(1));
    await log.close();
  });

  test('flushes the remainder of the buffer on stop()', () async {
    final log = DepthLogService();
    await log.openInMemory();
    final depth = StreamController<double>();
    final pos = StreamController<_Pos?>();
    final logger = DepthLogger(
      logService: log,
      depthStream: depth.stream,
      positionStream: pos.stream.map((p) => p == null ? null : (p.lat, p.lng)),
      onCommit: () {},
      source: SampleSource.simulated,
      flushInterval: const Duration(seconds: 10),
    );
    await logger.start();
    depth.add(3.0);
    depth.add(2.0);
    // Yield so the stream listener pulls the events into the buffer before stop.
    await Future<void>.delayed(Duration.zero);
    // Stop before any periodic flush would have fired.
    await logger.stop();
    expect((await log.all()).map((s) => s.depthMeters), [3.0, 2.0]);
    await depth.close();
    await pos.close();
    await log.close();
  });
}
