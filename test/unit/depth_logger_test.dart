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
