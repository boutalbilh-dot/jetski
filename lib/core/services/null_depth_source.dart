import 'dart:async';
import 'depth_source.dart';

/// Inert depth source: never emits. Used when the user has selected the
/// Bluetooth source but hasn't picked a device yet, so the rest of the
/// pipeline (alert engine, logger, UI) can wire up against a stable source
/// without needing null checks.
class NullDepthSource implements DepthSource {
  final _controller = StreamController<double>.broadcast();

  @override
  Stream<double> get depthMeters => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {
    if (!_controller.isClosed) await _controller.close();
  }
}
