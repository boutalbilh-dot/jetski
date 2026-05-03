import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'depth_source.dart';
import 'nmea_parser.dart';

class BluetoothService implements DepthSource {
  final String address; // MAC address chosen by user
  BluetoothConnection? _connection;
  final _controller = StreamController<double>.broadcast();
  String _buffer = '';

  BluetoothService(this.address);

  @override
  Stream<double> get depthMeters => _controller.stream;

  @override
  Future<void> start() async {
    if (_connection != null) {
      throw StateError('BluetoothService already started');
    }
    _connection = await BluetoothConnection.toAddress(address);
    _connection!.input!.listen(_onBytes, onDone: stop);
  }

  void _onBytes(List<int> bytes) {
    _buffer += utf8.decode(bytes, allowMalformed: true);
    while (true) {
      final nl = _buffer.indexOf('\n');
      if (nl == -1) break;
      final line = _buffer.substring(0, nl);
      _buffer = _buffer.substring(nl + 1);
      final d = NmeaParser.depthMeters(line);
      if (d != null) _controller.add(d);
    }
  }

  /// List all currently bonded Bluetooth devices.
  static Future<List<BluetoothDevice>> bondedDevices() {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  @override
  Future<void> stop() async {
    await _connection?.close();
    _connection = null;
    _buffer = '';
  }
}
