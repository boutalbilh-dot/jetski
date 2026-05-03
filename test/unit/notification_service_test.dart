import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/alert_engine.dart';
import 'package:projet_jetski/core/services/notification_service.dart';

class FakeBackend implements NotificationBackend {
  final calls = <String>[];
  @override
  Future<void> vibratePattern(List<int> pattern) async {
    calls.add('vibrate:${pattern.join(",")}');
  }

  @override
  Future<void> playWarning() async => calls.add('audio:warning');
  @override
  Future<void> playDanger() async => calls.add('audio:danger');
  @override
  Future<void> stopAudio() async => calls.add('audio:stop');
  @override
  Future<void> cancelVibration() async => calls.add('vibrate:cancel');
}

void main() {
  group('NotificationService', () {
    test('on warning transition: triggers warning vibration + sound', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.warning);
      expect(fake.calls, contains('audio:warning'));
      expect(fake.calls.any((c) => c.startsWith('vibrate:')), isTrue);
    });

    test('on danger transition: triggers danger vibration + sound', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.danger);
      expect(fake.calls, contains('audio:danger'));
    });

    test('on safe transition: cancels vibration and stops audio', () {
      final fake = FakeBackend();
      final svc = NotificationService(fake);
      svc.handleTransition(AlertLevel.safe);
      expect(fake.calls, contains('audio:stop'));
      expect(fake.calls, contains('vibrate:cancel'));
    });
  });
}
