import 'dart:async';
import '../models/depth_sample.dart';
import 'depth_log_service.dart';

class DepthLogger {
  /// Hard cap on in-memory buffered samples. At 10 Hz this is ~5 minutes of
  /// readings — well above the 2 s flush interval, so we only ever hit it if
  /// SQLite is wedged. Drop-oldest keeps memory bounded without crashing.
  static const int _bufferCap = 3000;

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
  Future<void>? _inflightFlush;

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
    if (_buffer.length >= _bufferCap) {
      // Drop the oldest 10% in one shot — far cheaper than removeAt(0) on
      // every insert (which is O(n) per call).
      _buffer.removeRange(0, _bufferCap ~/ 10);
    }
    _buffer.add(DepthSample(
      timestamp: DateTime.now().toUtc(),
      depthMeters: depth,
      latitude: _lastPos?.$1,
      longitude: _lastPos?.$2,
      source: source,
    ));
  }

  Future<void> _flush() {
    // Coalesce: if a flush is already running, wait for it instead of starting
    // another. Prevents overlapping inserts and lets stop() reliably drain.
    if (_inflightFlush != null) return _inflightFlush!;
    if (_buffer.isEmpty) return Future.value();
    final batch = List<DepthSample>.of(_buffer);
    _buffer.clear();
    final f = () async {
      try {
        await logService.addAll(batch);
        onCommit();
      } finally {
        _inflightFlush = null;
      }
    }();
    _inflightFlush = f;
    return f;
  }

  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _depthSub?.cancel();
    await _posSub?.cancel();
    _depthSub = null;
    _posSub = null;
    // Wait for any flush already in flight, then drain anything that arrived
    // between its start and now.
    if (_inflightFlush != null) await _inflightFlush;
    await _flush();
  }
}
