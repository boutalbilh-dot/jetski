import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/nmea_sentence.dart';

void main() {
  group('NmeaSentence.tryParse', () {
    test('parses a valid \$DPT sentence', () {
      // Checksum of 'SDDPT,3.5,0.5' is 0x54
      final s = NmeaSentence.tryParse(r'$SDDPT,3.5,0.5*54');
      expect(s, isNotNull);
      expect(s!.talker, 'SD');
      expect(s.type, 'DPT');
      expect(s.fields, ['3.5', '0.5']);
    });

    test('returns null on bad checksum', () {
      final s = NmeaSentence.tryParse(r'$SDDPT,3.5,0.5*FF');
      expect(s, isNull);
    });

    test('returns null when missing \$ prefix', () {
      expect(NmeaSentence.tryParse('SDDPT,3.5,0.5*54'), isNull);
    });

    test('returns null when missing checksum delimiter', () {
      expect(NmeaSentence.tryParse(r'$SDDPT,3.5,0.5'), isNull);
    });

    test('returns null on empty input', () {
      expect(NmeaSentence.tryParse(''), isNull);
    });

    test('handles trailing CR/LF', () {
      final s = NmeaSentence.tryParse('\$SDDPT,3.5,0.5*54\r\n');
      expect(s, isNotNull);
      expect(s!.type, 'DPT');
    });
  });
}
