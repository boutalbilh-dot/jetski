import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/services/nmea_parser.dart';

void main() {
  group('NmeaParser.depthMeters', () {
    test('reads metres from \$DPT', () {
      // $SDDPT,3.5,0.5*54 — depth 3.5 m, offset 0.5 m
      expect(NmeaParser.depthMeters(r'$SDDPT,3.5,0.5*54'), 3.5);
    });

    test('reads metres from \$DBT (uses M field, not feet)', () {
      // Body "SDDBT,11.5,f,3.50,M,1.91,F" XOR = 0x3C
      expect(NmeaParser.depthMeters(r'$SDDBT,11.5,f,3.50,M,1.91,F*3C'), 3.50);
    });

    test('returns null on \$GLL (irrelevant sentence)', () {
      // GLL is a position sentence, not a depth one — depthMeters must return null
      expect(NmeaParser.depthMeters(r'$GPGLL,4807.038,N,01131.000,E,123519,A*25'), isNull);
    });

    test('returns null on garbage', () {
      expect(NmeaParser.depthMeters('not a sentence'), isNull);
    });

    test('returns null when depth field is empty', () {
      // Checksum of 'SDDPT,,0.5' = 0x7C — empty depth field
      expect(NmeaParser.depthMeters(r'$SDDPT,,0.5*7C'), isNull);
    });
  });
}
