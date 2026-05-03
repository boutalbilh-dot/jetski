import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/wifi_nmea_service.dart';

/// Picks an OS-assigned free port by binding+closing a transient UDP socket,
/// so each test runs against a distinct port (no conflicts under parallel runs).
Future<int> _pickFreePort() async {
  final s = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final p = s.port;
  s.close();
  return p;
}

/// Build a valid NMEA sentence `\$<body>*<XOR>` with checksum computed.
String _nmea(String body) {
  var x = 0;
  for (final c in body.codeUnits) {
    x ^= c;
  }
  return '\$$body*${x.toRadixString(16).toUpperCase().padLeft(2, '0')}\r\n';
}

void main() {
  test('emits depth when a valid NMEA \$DPT datagram arrives', () async {
    final port = await _pickFreePort();
    final svc = WifiNmeaService(port: port);
    await svc.start();

    final next = svc.depthMeters.first;
    final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    sender.send(
      _nmea('SDDPT,3.2,0.0').codeUnits,
      InternetAddress.loopbackIPv4,
      port,
    );
    sender.close();

    expect(await next.timeout(const Duration(seconds: 2)), 3.2);
    await svc.stop();
  });

  test('handles multiple sentences in a single datagram', () async {
    final port = await _pickFreePort();
    final svc = WifiNmeaService(port: port);
    await svc.start();

    final samples = <double>[];
    final sub = svc.depthMeters.listen(samples.add);

    final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    sender.send(
      (_nmea('SDDPT,1.5,0.0') + _nmea('SDDPT,2.5,0.0')).codeUnits,
      InternetAddress.loopbackIPv4,
      port,
    );
    sender.close();

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    await svc.stop();
    expect(samples, [1.5, 2.5]);
  });

  test('ignores garbage datagrams without crashing', () async {
    final port = await _pickFreePort();
    final svc = WifiNmeaService(port: port);
    await svc.start();

    final samples = <double>[];
    final sub = svc.depthMeters.listen(samples.add);

    final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    sender.send('not nmea\n'.codeUnits, InternetAddress.loopbackIPv4, port);
    sender.send('\$GPGGA,whatever\n'.codeUnits,
        InternetAddress.loopbackIPv4, port);
    sender.send(
      _nmea('SDDPT,4.0,0.0').codeUnits,
      InternetAddress.loopbackIPv4,
      port,
    );
    sender.close();

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    await svc.stop();
    expect(samples, [4.0]);
  });

  test('emits listening state on start', () async {
    final port = await _pickFreePort();
    final svc = WifiNmeaService(port: port);
    final states = <WifiConnectionState>[];
    final sub = svc.connectionState.listen(states.add);
    await svc.start();
    await Future<void>.delayed(Duration.zero);
    expect(svc.currentState, WifiConnectionState.listening);
    await svc.stop();
    await sub.cancel();
    expect(states, contains(WifiConnectionState.listening));
  });

  test('cannot start twice', () async {
    final port = await _pickFreePort();
    final svc = WifiNmeaService(port: port);
    await svc.start();
    expect(() => svc.start(), throwsStateError);
    await svc.stop();
  });
}
