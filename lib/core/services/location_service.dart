import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position>? _stream;

  /// Request permission and start streaming positions. Returns null if the
  /// user denies permission.
  Future<Stream<Position>?> start() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    _stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    );
    return _stream;
  }
}
