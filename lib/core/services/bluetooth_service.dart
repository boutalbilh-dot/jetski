import 'dart:async';

import 'depth_source.dart';

// NOTE: flutter_bluetooth_serial 0.4.0 (the only Classic SPP plugin we'd
// found) is unmaintained and fails to build under AGP 8 (no `namespace`
// declared, deprecated jcenter / compileSdkVersion 30). Until we migrate
// the BT pipeline to a maintained alternative (BLE via flutter_blue_plus,
// or a different SPP package), the Bluetooth source is a no-op stub: the
// rest of the pipeline still wires up cleanly, but `start()` raises an
// error state that surfaces via the connection indicator.

enum BluetoothConnectionState { disconnected, connecting, connected, error }

/// Stand-in for a real bonded Bluetooth device — keeps the picker UI
/// compiling against a stable type without depending on the legacy plugin.
class BluetoothDevice {
  final String? name;
  final String address;
  const BluetoothDevice({this.name, required this.address});
}

class BluetoothService implements DepthSource {
  static const _unsupportedMessage =
      'Bluetooth source is not available in this build. '
      'Use Simulation, WiFi or Replay mode instead.';

  final String address;
  final _depthController = StreamController<double>.broadcast();
  final _stateController = StreamController<BluetoothConnectionState>.broadcast();
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  final String _lastError = _unsupportedMessage;

  BluetoothService(this.address);

  @override
  Stream<double> get depthMeters => _depthController.stream;

  Stream<BluetoothConnectionState> get connectionState =>
      _stateController.stream;
  BluetoothConnectionState get currentState => _state;
  String? get lastError => _lastError;

  @override
  Future<void> start() async {
    _state = BluetoothConnectionState.error;
    if (!_stateController.isClosed) {
      _stateController.add(BluetoothConnectionState.error);
    }
  }

  /// Always returns an empty list in this build — the picker handles the
  /// empty case by telling the user to pair a device first.
  static Future<List<BluetoothDevice>> bondedDevices() async => const [];

  @override
  Future<void> stop() async {
    _state = BluetoothConnectionState.disconnected;
    if (!_stateController.isClosed) await _stateController.close();
    if (!_depthController.isClosed) await _depthController.close();
  }
}
