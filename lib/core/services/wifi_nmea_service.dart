import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'depth_source.dart';
import 'nmea_parser.dart';

/// Connection state of a [WifiNmeaService].
enum WifiConnectionState { idle, listening, error }

/// Listens for NMEA 0183 sentences broadcast over UDP on the local network
/// and emits the parsed depth values. Compatible with:
///
/// - Deeper CHIRP+, CHIRP+ 2.0, PRO+ 2.0 (built-in NMEA-over-UDP mode)
/// - Yacht Devices YDWN-02, Digital Yacht WLN10/WLN30, and other marine
///   WiFi gateways
/// - Lowrance HDS / Humminbird with WiFi sharing enabled
///
/// The user must connect the phone to the device's WiFi network (or the
/// shared boat network) before the service can receive datagrams.
class WifiNmeaService implements DepthSource {
  /// Hard cap on the line-assembly buffer (see BluetoothService for rationale).
  static const int _maxBufferBytes = 4096;

  final int port;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSub;
  final _depthController = StreamController<double>.broadcast();
  final _stateController = StreamController<WifiConnectionState>.broadcast();
  final StringBuffer _buffer = StringBuffer();

  WifiConnectionState _state = WifiConnectionState.idle;
  String? _lastError;

  WifiNmeaService({this.port = 10110});

  @override
  Stream<double> get depthMeters => _depthController.stream;

  Stream<WifiConnectionState> get connectionState => _stateController.stream;
  WifiConnectionState get currentState => _state;
  String? get lastError => _lastError;

  void _emitState(WifiConnectionState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  @override
  Future<void> start() async {
    if (_socket != null) {
      throw StateError('WifiNmeaService already started');
    }
    try {
      _socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socketSub = _socket!.listen(
        _onSocketEvent,
        onError: (Object e) {
          _lastError = e.toString();
          _emitState(WifiConnectionState.error);
        },
        onDone: () => _emitState(WifiConnectionState.idle),
      );
      _emitState(WifiConnectionState.listening);
    } catch (e) {
      _lastError = e.toString();
      _emitState(WifiConnectionState.error);
      rethrow;
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _socket?.receive();
    if (dg == null) return;
    _buffer.write(utf8.decode(dg.data, allowMalformed: true));
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

  @override
  Future<void> stop() async {
    await _socketSub?.cancel();
    _socketSub = null;
    _socket?.close();
    _socket = null;
    _buffer.clear();
    _emitState(WifiConnectionState.idle);
    if (!_stateController.isClosed) await _stateController.close();
    if (!_depthController.isClosed) await _depthController.close();
  }
}
