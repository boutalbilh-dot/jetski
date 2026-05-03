import 'dart:async';
import '../models/depth_sample.dart';
import 'depth_log_service.dart';

class DepthLogger {
  final DepthLogService logService;
  final Stream<double> depthStream;
  final Stream<(double, double)?> positionStream;
  final void Function() onCommit;
  final SampleSource source;
  final Duration flushInterval;

  StreamSubscription<double>? _depthSub;
  StreamSubscription<(double, double)?>? _posSub;
  Timer? _flushTimer;
  (double, double)? _lastPos;
  final List<DepthSample> _buffer = [];

  DepthLogger({
    required this.logService,
    required this.depthStream,
    required this.positionStream,
    required this.onCommit,
    this.source = SampleSource.real,
    this.flushInterval = const Duration(seconds: 2),
  });

  /// Awaits the underlying log service open before subscribing — without this,
  /// samples that arrive in the same microtask as start() race the open() call
  /// and crash the stream's zone with StateError.
  Future<void> start() async {
    await logService.open();
    _posSub = positionStream.listen((p) => _lastPos = p);
    _depthSub = depthStream.listen(_enqueue);
    _flushTimer = Timer.periodic(flushInterval, (_) => _flush());
  }

  void _enqueue(double depth) {
    _buffer.add(DepthSample(
      timestamp: DateTime.now().toUtc(),
      depthMeters: depth,
      latitude: _lastPos?.$1,
      longitude: _lastPos?.$2,
      source: source,
    ));
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<DepthSample>.of(_buffer);
    _buffer.clear();
    await logService.addAll(batch);
    onCommit();
  }

  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _depthSub?.cancel();
    await _posSub?.cancel();
    _depthSub = null;
    _posSub = null;
    await _flush();
  }
}
