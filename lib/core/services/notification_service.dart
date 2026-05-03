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
  final _player = AudioPlayer();

  @override
  Future<void> vibratePattern(List<int> pattern) async {
    // vibration: ^2.0.0 — hasVibrator() returns Future<bool>.
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  @override
  Future<void> cancelVibration() => Vibration.cancel();

  @override
  Future<void> playWarning() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/warning.wav'));
  }

  @override
  Future<void> playDanger() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/danger.wav'));
  }

  @override
  Future<void> stopAudio() => _player.stop();
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
