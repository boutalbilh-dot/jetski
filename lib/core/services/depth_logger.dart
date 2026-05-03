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
