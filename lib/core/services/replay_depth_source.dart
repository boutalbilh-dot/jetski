import 'dart:async';
import '../models/depth_sample.dart';
import 'depth_log_service.dart';
import 'depth_source.dart';

const Duration kReplayDefaultLookback = Duration(hours: 24);

/// Replays previously-recorded depth samples from the local SQLite log,
/// emitting them at their original cadence so the rest of the pipeline
/// (alert engine, notifications, map track) sees a realistic stream.
///
/// Useful for debugging an alert/UI issue without going back on the water:
/// take any recorded session and feed it back through the live pipeline.
class ReplayDepthSource implements DepthSource {
  final DepthLogService logService;

  /// Pulls samples whose timestamp is within `now - lookbackWindow .. now`
  /// when `start()` is called. The lookback is captured at start time —
  /// later writes during playback are not picked up.
  final Duration lookbackWindow;

  /// When the playback reaches the end of the loaded samples, restart
  /// from the first one after [loopGap]. Set to `false` to play once.
  final bool loop;

  /// Delay inserted between the end of one playback pass and the start
  /// of the next one. Only used when [loop] is true.
  final Duration loopGap;

  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  List<DepthSample> _samples = const [];
  int _idx = 0;
  bool _started = false;

  ReplayDepthSource({
    required this.logService,
    this.lookbackWindow = kReplayDefaultLookback,
    this.loop = true,
    this.loopGap = const Duration(seconds: 1),
  });

  @override
  Stream<double> get depthMeters => _controller.stream;

  /// Number of samples currently loaded for playback. Available after
  /// `start()` resolves; useful for the UI to show "no recordings yet".
  int get loadedSampleCount => _samples.length;

  @override
  Future<void> start() async {
    if (_started) {
      throw StateError('ReplayDepthSource already started');
    }
    _started = true;
    final now = DateTime.now().toUtc();
    // Only replay samples that came from a real sensor. The logger writes
    // replayed samples back to SQLite as `simulated`, so filtering here
    // prevents a feedback loop where a replay session re-replays its own
    // output the next time the user starts replay mode.
    _samples = await logService.range(
      from: now.subtract(lookbackWindow),
      to: now,
      source: SampleSource.real,
    );
    _idx = 0;
    if (_samples.isEmpty) return; // nothing to play; stream stays open but idle
    _emitAndScheduleNext();
  }

  void _emitAndScheduleNext() {
    if (_controller.isClosed) return;
    if (_samples.isEmpty) return;
    if (_idx < 0 || _idx >= _samples.length) return;

    _controller.add(_samples[_idx].depthMeters);
    final nextIdx = _idx + 1;

    if (nextIdx >= _samples.length) {
      if (!loop) return;
      _idx = 0;
      _timer = Timer(loopGap, _emitAndScheduleNext);
      return;
    }

    final delta = _samples[nextIdx].timestamp.difference(_samples[_idx].timestamp);
    _idx = nextIdx;
    _timer = Timer(delta.isNegative ? Duration.zero : delta, _emitAndScheduleNext);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
