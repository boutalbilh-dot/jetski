abstract class DepthSource {
  /// Stream of depth readings in metres. Emits at the source's natural rate
  /// (>= 1 Hz for real sensors and the simulation).
  Stream<double> get depthMeters;

  /// Begin emitting. Throws StateError if already started.
  Future<void> start();

  /// Stop emitting and release resources. After calling, the depthMeters stream
  /// will emit done; the source is no longer usable. To resume, create a new
  /// instance.
  Future<void> stop();
}
