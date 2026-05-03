import '../models/nmea_sentence.dart';

class NmeaParser {
  /// Returns the depth in metres from a single NMEA line, or null if the line
  /// is not a depth sentence or is invalid.
  static double? depthMeters(String line) {
    final s = NmeaSentence.tryParse(line);
    if (s == null) return null;

    if (s.type == 'DPT') {
      // Field 0 = depth in metres (relative to transducer)
      if (s.fields.isEmpty || s.fields[0].isEmpty) return null;
      return double.tryParse(s.fields[0]);
    }

    if (s.type == 'DBT') {
      // Format: feet, f, metres, M, fathoms, F
      // Pick the metre value (index 2) when its unit indicator (index 3) is 'M'.
      if (s.fields.length < 4) return null;
      if (s.fields[3].toUpperCase() != 'M') return null;
      if (s.fields[2].isEmpty) return null;
      return double.tryParse(s.fields[2]);
    }

    return null;
  }
}
