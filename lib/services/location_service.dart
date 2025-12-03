import 'dart:async';
import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  /// Check and request GPS + permissions
  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if GPS is ON
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) throw Exception("Location service not enabled");
    }

    // Check app permission
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception("Location permission denied");
      }
    }
  }

  /// Stream location continuously (real time)
  Stream<LocationData> getContinuousLocationStream() async* {
    await _checkPermissions();

    // Best settings for Uber-like tracking
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000,      // every 2 seconds
      distanceFilter: 5,   // every 5 meters movement
    );

    yield* _location.onLocationChanged;
  }
}
