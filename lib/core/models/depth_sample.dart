enum SampleSource { real, simulated }

class DepthSample {
  static const tableName = 'depth_samples';
  static const colTimestamp = 'timestamp_ms';
  static const colDepth = 'depth_m';
  static const colLat = 'lat';
  static const colLng = 'lng';
  static const colSource = 'source';

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

  static int encodeTimestamp(DateTime t) => t.toUtc().millisecondsSinceEpoch;

  Map<String, Object?> toMap() => {
        colTimestamp: encodeTimestamp(timestamp),
        colDepth: depthMeters,
        colLat: latitude,
        colLng: longitude,
        colSource: source.name,
      };

  factory DepthSample.fromMap(Map<String, Object?> m) => DepthSample(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            m[colTimestamp]! as int,
            isUtc: true),
        depthMeters: (m[colDepth]! as num).toDouble(),
        latitude: (m[colLat] as num?)?.toDouble(),
        longitude: (m[colLng] as num?)?.toDouble(),
        source: SampleSource.values.byName(m[colSource]! as String),
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
