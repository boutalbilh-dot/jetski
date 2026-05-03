enum SampleSource { real, simulated }

class DepthSample {
  final DateTime timestamp;
  final double depthMeters;
  final double? latitude;
  final double? longitude;
  final SampleSource source;

  const DepthSample({
    required this.timestamp,
    required this.depthMeters,
    required this.source,
    this.latitude,
    this.longitude,
  });

  Map<String, Object?> toMap() => {
        'timestamp_ms': timestamp.toUtc().millisecondsSinceEpoch,
        'depth_m': depthMeters,
        'lat': latitude,
        'lng': longitude,
        'source': source.name,
      };

  factory DepthSample.fromMap(Map<String, Object?> m) => DepthSample(
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(m['timestamp_ms']! as int, isUtc: true),
        depthMeters: (m['depth_m']! as num).toDouble(),
        latitude: (m['lat'] as num?)?.toDouble(),
        longitude: (m['lng'] as num?)?.toDouble(),
        source: SampleSource.values.byName(m['source']! as String),
      );

  @override
  bool operator ==(Object other) =>
      other is DepthSample &&
      timestamp == other.timestamp &&
      depthMeters == other.depthMeters &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      source == other.source;

  @override
  int get hashCode =>
      Object.hash(timestamp, depthMeters, latitude, longitude, source);
}
