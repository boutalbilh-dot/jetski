import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Stream<Position>?>? _startFuture;

  /// Request permission and start streaming positions. Returns null if the
  /// user denies permission. Idempotent: subsequent calls return the same
  /// future, so multiple subscribers share a single permission prompt and
  /// position stream.
  Future<Stream<Position>?> start() {
    return _startFuture ??= _startInternal();
  }

  Future<Stream<Position>?> _startInternal() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    );
  }
}
