import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:location/location.dart';

class StompService {
  StompClient? _client;
  final _storage = const FlutterSecureStorage();

  // ⚠️ FIX: Use non-secure 'ws' protocol for non-SSL Spring Boot port 8080
  final String _socketUrl = "ws://10.0.2.2:8080/ws";

  bool isConnected() {
    return _client?.connected ?? false;
  }

  Future<void> connect() async {
    if (isConnected()) return;

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      print("Error: No token found for STOMP connection.");
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) => print("STOMP Client connected successfully!"),
        onWebSocketError: (dynamic error) => print("WebSocket Error: $error"),
        // CRITICAL: Send the token in both headers for the backend interceptor
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        // Automatically try to reconnect on disconnect/error
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  void sendLocation(LocationData locationData) {
    if (!isConnected() || locationData.latitude == null) {
      print("Warning: Location send skipped (STOMP not connected).");
      return;
    }

    final locationUpdate = {
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
    };

    _client?.send(
      destination: '/app/driver.location',
      body: jsonEncode(locationUpdate),
      headers: {},
    );
  }

  void disconnect() {
    _client?.deactivate();
  }
}