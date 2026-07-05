import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/stomp_service.dart';
import '../models/ambulance_model.dart';
import 'login_screen.dart';

class PoliceMapScreen extends StatefulWidget {
  const PoliceMapScreen({super.key});

  @override
  State<PoliceMapScreen> createState() => _PoliceMapScreenState();
}

class _PoliceMapScreenState extends State<PoliceMapScreen> {

  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final StompService _stompService = StompService();

  GoogleMapController? _mapController;
  LocationData? _currentLocation;

  Marker? _policeMarker;
  final Map<String, Marker> _ambulanceMarkers = {};

  BitmapDescriptor? _policeIcon;
  BitmapDescriptor? _ambulanceIcon;

  StreamSubscription<LocationData>? _locationSub;
  StreamSubscription? _stompSub;

  final LatLng _initialCamera = const LatLng(18.5204, 73.8567);

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startLocation();

    // 🔹 CONNECT to websocket
    _stompService.connect(onConnect: () {
      _listenAmbulances();     // <--- IMPORTANT
    });
  }

  void _listenAmbulances() {
    _stompSub = _stompService.ambulanceStream.listen((data) {
      try {
        final amb = Ambulance.fromJson(data);
        showAmbulance(amb);
      } catch (e) {
        print("Error parsing ambulance JSON: $e");
        print(data);
      }
    });
  }

  Future<void> _loadIcons() async {
    _policeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),
      'assets/icons/police.png',
    );

    _ambulanceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),
      'assets/icons/ambulance.png',
    );

    setState(() {});
  }

  void _startLocation() {
    _locationSub = _locationService.getContinuousLocationStream().listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      _currentLocation = loc;
      _updatePoliceMarker(LatLng(loc.latitude!, loc.longitude!));
    });
  }

  void _updatePoliceMarker(LatLng pos) {
    _policeMarker = Marker(
      markerId: const MarkerId("POLICE"),
      position: pos,
      icon: _policeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: "Traffic Police"),
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 15),
      ),
    );

    setState(() {});
  }

  // 🔹 Render Ambulance on Map
  void showAmbulance(Ambulance amb) {
    if (amb.location == null) return;

    _ambulanceMarkers[amb.id] = Marker(
      markerId: MarkerId(amb.id),
      position: amb.location!,
      icon: _ambulanceIcon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(title: "Ambulance ${amb.driverName ?? ''}"),
    );

    setState(() {});
  }

  Future<void> _logout() async {
    _locationSub?.cancel();
    _stompSub?.cancel();
    _stompService.disconnect();
    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (_) => false,
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _stompSub?.cancel();
    _stompService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCamera,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              if (_policeMarker != null) _policeMarker!,
              ..._ambulanceMarkers.values
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _topTitle(),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Traffic Police - Ambulance Tracking",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
