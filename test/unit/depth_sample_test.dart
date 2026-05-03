import 'package:flutter_test/flutter_test.dart';
import 'package:projet_jetski/core/models/depth_sample.dart';

void main() {
  group('DepthSample', () {
    test('constructs with required fields', () {
      final s = DepthSample(
        timestamp: DateTime.utc(2026, 5, 3, 12, 0, 0),
        depthMeters: 3.2,
        latitude: 46.81,
        longitude: -71.21,
        source: SampleSource.simulated,
      );
      expect(s.depthMeters, 3.2);
      expect(s.source, SampleSource.simulated);
      expect(s.latitude, 46.81);
    });

    test('latitude and longitude are optional (sensor-only sample)', () {
      final s = DepthSample(
        timestamp: DateTime.utc(2026, 5, 3),
        depthMeters: 1.5,
        source: SampleSource.real,
      );
      expect(s.latitude, isNull);
      expect(s.longitude, isNull);
    });

    test('two samples with same fields are equal', () {
      final t = DateTime.utc(2026, 5, 3);
      final a = DepthSample(timestamp: t, depthMeters: 2.0, source: SampleSource.real);
      final b = DepthSample(timestamp: t, depthMeters: 2.0, source: SampleSource.real);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toMap and fromMap roundtrip', () {
      final t = DateTime.utc(2026, 5, 3, 14, 30);
      final original = DepthSample(
        timestamp: t,
        depthMeters: 2.7,
        latitude: 46.81,
        longitude: -71.21,
        source: SampleSource.real,
      );
      final restored = DepthSample.fromMap(original.toMap());
      expect(restored, equals(original));
    });
  });
}
