import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/providers/app_providers.dart';
import 'package:projet_jetski/core/services/null_depth_source.dart';
import 'package:projet_jetski/core/services/simulation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('depthSourceProvider returns SimulationService when mode is simulation',
      () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(depthSourceProvider), isA<SimulationService>());
  });

  test('depthSourceProvider returns NullDepthSource when mode is bluetooth and no address picked',
      () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(sourceConfigProvider.notifier).setMode(SourceMode.bluetooth);
    expect(c.read(depthSourceProvider), isA<NullDepthSource>());
  });

  test('source mode + address persist across container restarts', () async {
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    await c1.read(sourceConfigProvider.notifier).setMode(SourceMode.wifi);
    await c1
        .read(sourceConfigProvider.notifier)
        .setBluetoothAddress('AA:BB:CC:DD:EE:FF');

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(sourceConfigProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final cfg = c2.read(sourceConfigProvider);
    expect(cfg.mode, SourceMode.wifi);
    expect(cfg.bluetoothAddress, 'AA:BB:CC:DD:EE:FF');
  });

  test('legacy bluetooth mode is silently migrated to simulation on load',
      () async {
    final p1 = await SharedPreferences.getInstance();
    await p1.setString('src.mode', 'bluetooth');

    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sourceConfigProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(sourceConfigProvider).mode, SourceMode.simulation);

    final p2 = await SharedPreferences.getInstance();
    expect(p2.getString('src.mode'), 'simulation');
  });

  test('clearing the bluetooth address removes the persisted entry', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c
        .read(sourceConfigProvider.notifier)
        .setBluetoothAddress('AA:BB:CC:DD:EE:FF');
    await c.read(sourceConfigProvider.notifier).setBluetoothAddress(null);
    expect(c.read(sourceConfigProvider).bluetoothAddress, isNull);
  });
}
