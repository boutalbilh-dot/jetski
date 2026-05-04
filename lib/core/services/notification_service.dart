import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'alert_engine.dart';

abstract class NotificationBackend {
  Future<void> vibratePattern(List<int> pattern);
  Future<void> cancelVibration();
  Future<void> playWarning();
  Future<void> playDanger();
  Future<void> stopAudio();
}

class RealBackend implements NotificationBackend {
  final _warningPlayer = AudioPlayer();
  final _dangerPlayer = AudioPlayer();
  bool? _hasVibrator;

  RealBackend() {
    // Preload assets so the first transition into warning/danger doesn't
    // stall on disk I/O — that's exactly the moment latency hurts most.
    _warningPlayer.setReleaseMode(ReleaseMode.stop);
    _warningPlayer.setSource(AssetSource('sounds/warning.wav'));
    _dangerPlayer.setReleaseMode(ReleaseMode.stop);
    _dangerPlayer.setSource(AssetSource('sounds/danger.wav'));
  }

  @override
  Future<void> vibratePattern(List<int> pattern) async {
    final has = _hasVibrator ??= await Vibration.hasVibrator();
    if (has == true) {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  @override
  Future<void> cancelVibration() => Vibration.cancel();

  @override
  Future<void> playWarning() async {
    await _warningPlayer.stop();
    await _warningPlayer.resume();
  }

  @override
  Future<void> playDanger() async {
    await _dangerPlayer.stop();
    await _dangerPlayer.resume();
  }

  @override
  Future<void> stopAudio() async {
    await _warningPlayer.stop();
    await _dangerPlayer.stop();
  }
}

class NotificationService {
  final NotificationBackend backend;
  NotificationService(this.backend);

  /// Pattern: short single beep every 2s -> [delay, on, off, on, off]
  static const _warningPattern = [0, 200, 1800];

  /// Pattern: three short bursts every 1s
  static const _dangerPattern = [0, 150, 100, 150, 100, 150, 600];

  void handleTransition(AlertLevel level) {
    switch (level) {
      case AlertLevel.safe:
        backend.cancelVibration();
        backend.stopAudio();
      case AlertLevel.warning:
        backend.vibratePattern(_warningPattern);
        backend.playWarning();
      case AlertLevel.danger:
        backend.vibratePattern(_dangerPattern);
        backend.playDanger();
    }
  }
}
