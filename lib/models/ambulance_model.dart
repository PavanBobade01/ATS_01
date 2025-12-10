import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ambulance {
  final String id;
  final String? vehicleNumber;
  final String? driverName;
  final String? status;
  final LatLng? location;
  final DateTime? lastUpdated;

  // Police-only fields (optional)
  final double? distanceKm;
  final String? priority;

  Ambulance({
    required this.id,
    this.vehicleNumber,
    this.driverName,
    this.status,
    this.location,
    this.lastUpdated,
    this.distanceKm,
    this.priority,
  });

  factory Ambulance.fromJson(Map<String, dynamic> json) {
    // ---- ID ----
    final dynamic rawId = json['id'];
    final String id = rawId?.toString() ?? '';

    // ---- LOCATION (GeoJSON Point) ----
    LatLng? loc;
    final locationJson = json['location'];

    if (locationJson != null &&
        locationJson is Map &&
        locationJson['coordinates'] is List &&
        (locationJson['coordinates'] as List).length == 2) {
      final coords = locationJson['coordinates'] as List;
      final double lng = (coords[0] as num).toDouble();
      final double lat = (coords[1] as num).toDouble();
      loc = LatLng(lat, lng); // GeoJSON → Google Maps
    }

    // ---- lastUpdated ----
    DateTime? updated;
    final lastUpdatedStr = json['lastUpdated'];
    if (lastUpdatedStr is String) {
      updated = DateTime.tryParse(lastUpdatedStr);
    }

    return Ambulance(
      id: id,
      vehicleNumber: json['vehicleNumber'] as String?,
      driverName: json['driverName'] as String?,
      status: json['status'] as String?,
      location: loc,
      lastUpdated: updated,

      // Police extras
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      priority: json['priority'] as String?,
    );
  }

  Ambulance copyWith({
    String? vehicleNumber,
    String? driverName,
    String? status,
    LatLng? location,
    DateTime? lastUpdated,
    double? distanceKm,
    String? priority,
  }) {
    return Ambulance(
      id: id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      distanceKm: distanceKm ?? this.distanceKm,
      priority: priority ?? this.priority,
    );
  }
}
