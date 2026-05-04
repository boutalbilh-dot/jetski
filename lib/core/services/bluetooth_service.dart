import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'depth_source.dart';
import 'nmea_parser.dart';

enum BluetoothConnectionState { disconnected, connecting, connected, error }

class BluetoothService implements DepthSource {
  /// Hard cap on the line-assembly buffer. NMEA sentences are <80 bytes, so
  /// 4 KiB of unterminated junk means we're not actually receiving NMEA —
  /// drop it to avoid unbounded growth on a wedged stream.
  static const int _maxBufferBytes = 4096;

  final String address; // MAC address chosen by user
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  final _depthController = StreamController<double>.broadcast();
  final _stateController = StreamController<BluetoothConnectionState>.broadcast();
  final StringBuffer _buffer = StringBuffer();
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String? _lastError;

  BluetoothService(this.address);

  @override
  Stream<double> get depthMeters => _depthController.stream;

  Stream<BluetoothConnectionState> get connectionState => _stateController.stream;
  BluetoothConnectionState get currentState => _state;
  String? get lastError => _lastError;

  void _emitState(BluetoothConnectionState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  @override
  Future<void> start() async {
    if (_connection != null) {
      throw StateError('BluetoothService already started');
    }
    _emitState(BluetoothConnectionState.connecting);
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _inputSub = _connection!.input!.listen(
        _onBytes,
        onDone: () {
          _emitState(BluetoothConnectionState.disconnected);
          unawaited(stop());
        },
        onError: (Object e) {
          _lastError = e.toString();
          _emitState(BluetoothConnectionState.error);
        },
      );
      _emitState(BluetoothConnectionState.connected);
    } catch (e) {
      _lastError = e.toString();
      _emitState(BluetoothConnectionState.error);
      rethrow;
    }
  }

  void _onBytes(List<int> bytes) {
    _buffer.write(utf8.decode(bytes, allowMalformed: true));
    if (_buffer.length > _maxBufferBytes) {
      _buffer.clear();
      return;
    }
    final s = _buffer.toString();
    var start = 0;
    while (true) {
      final nl = s.indexOf('\n', start);
      if (nl == -1) break;
      final line = s.substring(start, nl);
      start = nl + 1;
      final d = NmeaParser.depthMeters(line);
      if (d != null && !_depthController.isClosed) _depthController.add(d);
    }
    _buffer.clear();
    if (start < s.length) _buffer.write(s.substring(start));
  }

  /// List all currently bonded Bluetooth devices.
  static Future<List<BluetoothDevice>> bondedDevices() {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  @override
  Future<void> stop() async {
    await _inputSub?.cancel();
    _inputSub = null;
    await _connection?.close();
    _connection = null;
    _buffer.clear();
    _emitState(BluetoothConnectionState.disconnected);
    if (!_stateController.isClosed) await _stateController.close();
    if (!_depthController.isClosed) await _depthController.close();
  }
}
