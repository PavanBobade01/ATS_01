import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ambulance {
  final String id;
  final String? vehicleNumber;
  final String? driverName;
  final String? status;        // e.g. ON_DUTY / OFF_DUTY
  final LatLng? location;      // For map
  final DateTime? lastUpdated;

  // Extra fields useful for police app (client-side only)
  final double? distanceKm;    // distance from police
  final String? priority;      // e.g. NORMAL / CRITICAL

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
    // ---- ID handling (int or string) ----
    final dynamic rawId = json['id'];
    final String id = rawId?.toString() ?? '';

    // ---- Location handling (GeoJSON Point) ----
    LatLng? loc;
    final locationJson = json['location'];
    if (locationJson != null &&
        locationJson is Map &&
        locationJson['coordinates'] is List &&
        (locationJson['coordinates'] as List).length == 2) {
      final coords = locationJson['coordinates'] as List;
      final double lng = (coords[0] as num).toDouble();
      final double lat = (coords[1] as num).toDouble();
      loc = LatLng(lat, lng); // [lng, lat] → (lat, lng)
    }

    // ---- lastUpdated parsing ----
    DateTime? updated;
    final lastUpdatedStr = json['lastUpdated'];
    if (lastUpdatedStr is String && lastUpdatedStr.isNotEmpty) {
      updated = DateTime.tryParse(lastUpdatedStr);
    }

    return Ambulance(
      id: id,
      vehicleNumber: json['vehicleNumber'] as String?,
      driverName: json['driverName'] as String?,
      status: json['status'] as String?,
      location: loc,
      lastUpdated: updated,
      priority: json['priority'] as String?,   // if backend sends it
    );
  }

  // Allows you to add distance later (for police app) without mutating
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
