import 'dart:async';
import 'dart:math';
import 'depth_source.dart';

enum SimulationScenario { approach, suddenDanger, unstable, manual }

class SimulationService implements DepthSource {
  SimulationScenario _scenario;
  final Duration tickInterval;
  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  int _tick = 0;
  double _manual = 2.0;
  final _rand = Random(42);

  SimulationService({
    required SimulationScenario scenario,
    this.tickInterval = const Duration(milliseconds: 200),
  }) : _scenario = scenario;

  SimulationScenario get scenario => _scenario;

  /// Switch the active scenario without restarting the service. Resets the
  /// internal tick counter so each scenario gets its expected starting state.
  void setScenario(SimulationScenario s) {
    if (_scenario == s) return;
    _scenario = s;
    _tick = 0;
  }

  @override
  Stream<double> get depthMeters => _controller.stream;

  void setManualDepth(double v) {
    _manual = v;
    if (_scenario == SimulationScenario.manual &&
        _timer != null &&
        !_controller.isClosed) {
      _controller.add(v);
    }
  }

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
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    final v = switch (_scenario) {
      SimulationScenario.approach => _approach(_tick),
      SimulationScenario.suddenDanger => _sudden(_tick),
      SimulationScenario.unstable => _unstable(),
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

  double _unstable() {
    // 2 m baseline +/- 0.6 m noise.
    return 2.0 + (_rand.nextDouble() - 0.5) * 1.2;
  }
}
