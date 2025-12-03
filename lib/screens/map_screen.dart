import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../services/auth_service.dart';
import '../services/stomp_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final AuthService _authService = AuthService();
  final StompService _stompService = StompService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  final LatLng _initialCameraPosition = const LatLng(18.5204, 73.8567);

  Marker? _driverMarker;
  BitmapDescriptor? _ambulanceIcon; // custom marker icon

  bool _isBroadcasting = false;
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _loadAmbulanceIcon();
    _stompService.connect();
    _startLocationListener();
  }

  // Load custom ambulance icon from assets
  Future<void> _loadAmbulanceIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/icons/ambulance.png', // make sure this path exists
    );
    setState(() {
      _ambulanceIcon = icon;
    });
  }

  void _startLocationListener() {
    _locationSubscription =
        _locationService.getContinuousLocationStream().listen(
              (LocationData locationData) {
            if (locationData.latitude == null ||
                locationData.longitude == null) return;

            _currentLocation = locationData;
            final newPos = LatLng(locationData.latitude!, locationData.longitude!);

            // Update marker
            _updateDriverMarker(newPos);

            // Smooth camera follow (Uber-style)
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: newPos, zoom: 16),
              ),
            );

            // Send location if ON duty
            if (_isBroadcasting) {
              _stompService.sendLocation(locationData);
            }
          },
          onError: (error) {
            debugPrint("Error getting location: $error");
          },
        );
  }

  void _updateDriverMarker(LatLng pos) {
    setState(() {
      _driverMarker = Marker(
        markerId: const MarkerId("driver_self"),
        position: pos,
        icon: _ambulanceIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "My Ambulance"),
      );
    });
  }

  void _toggleBroadcast() {
    // Check STOMP connection before toggling ON
    if (!_isBroadcasting && !_stompService.isConnected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection not ready. Try again."),
          backgroundColor: Colors.orange,
        ),
      );
      _stompService.connect();
      return;
    }

    setState(() {
      _isBroadcasting = !_isBroadcasting;
    });

    if (_isBroadcasting && _currentLocation != null) {
      _stompService.sendLocation(_currentLocation!);
    }
  }

  void _handleLogout() async {
    _locationSubscription?.cancel();
    _stompService.disconnect();
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _stompService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar -> full-screen map like Uber
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _driverMarker != null ? {_driverMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // hide default button
            zoomControlsEnabled: false,      // cleaner UI
          ),

          // Top overlay (title + logout), light & minimal
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    "Ambulance Driver",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black87),
                    onPressed: _handleLogout,
                    tooltip: "Logout",
                  ),
                ),
              ],
            ),
          ),

          // Bottom big pill button (GO ON DUTY / OFF DUTY)
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: ElevatedButton.icon(
              onPressed: _toggleBroadcast,
              icon: Icon(
                _isBroadcasting ? Icons.stop : Icons.local_hospital,
              ),
              label: Text(
                _isBroadcasting ? "GO OFF DUTY" : "GO ON DUTY",
              ),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor:
                _isBroadcasting ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
