// lib/services/stomp_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:location/location.dart';

/// Robust STOMP service for ATS.
/// - connect (jwt is read from secure storage)
/// - expose ambulanceStream for police UI to listen
/// - sendLocation for driver
class StompService {
  StompClient? _client;
  final _storage = const FlutterSecureStorage();

  // Stream of incoming ambulance messages (parsed JSON maps)
  final _ambulanceController =
  StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get ambulanceStream =>
      _ambulanceController.stream;

  // connection state stream
  final _connectedController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectedController.stream;

  // reconnect/backoff
  int _reconnectAttempt = 0;
  bool _manuallyDisconnected = false;
  Timer? _reconnectTimer;

  // Host / endpoint defaults. Override in constructor for device tests.
  final String host;
  final String endpoint;

  StompService({this.host = '10.0.2.2', this.endpoint = '/ws'});

  // For plain WebSocket STOMP (if you ever switch off SockJS)
  String get _wsUrl => 'ws://$host:8080$endpoint';

  // SockJS client in stomp_dart_client expects http/https, NOT ws
  String get _sockJsUrl => 'http://$host:8080$endpoint';

  bool isConnected() => _client?.connected ?? false;

  /// Connect using token stored in flutter_secure_storage under key 'jwt_token'
  Future<void> connect({void Function()? onConnect}) async {
    if (isConnected()) return;

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      debugPrint('STOMP: no token found in secure storage');
      return;
    }

    _manuallyDisconnected = false;
    _reconnectAttempt = 0;
    _connectedController.add(false);

    // Ensure previous client is cleared
    await disconnect();

    // Use SockJS variant for broad compatibility; if server doesn't use SockJS
    // you can switch to the plain StompConfig() using _wsUrl.
    final config = StompConfig.sockJS(
      url: _sockJsUrl, // MUST be http/https for SockJS
      stompConnectHeaders: {'Authorization': 'Bearer $token'},
      webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      onConnect: (StompFrame frame) {
        debugPrint('STOMP connected');
        _reconnectAttempt = 0;
        _connectedController.add(true);
        _subscribeToPoliceTopic();
        if (onConnect != null) onConnect();
      },
      onWebSocketError: (dynamic error) {
        debugPrint('STOMP WebSocket error: $error');
      },
      onStompError: (frame) {
        debugPrint('STOMP frame error: ${frame.body}');
      },
      onDisconnect: (frame) {
        debugPrint('STOMP disconnected');
        _connectedController.add(false);
        _tryReconnect(token);
      },
      // new API: these are Durations, not ints
      heartbeatIncoming: const Duration(milliseconds: 10000),
      heartbeatOutgoing: const Duration(milliseconds: 10000),
      // debug callbacks
      onUnhandledFrame: (f) => debugPrint('Unhandled frame: $f'),
      onUnhandledMessage: (m) => debugPrint('Unhandled message: $m'),
    );

    _client = StompClient(config: config);
    _client?.activate();
  }

  void _subscribeToPoliceTopic() {
    if (_client == null || !_client!.connected) return;

    // Subscribe once; if already subscribed, duplicates may occur so guard with try/catch
    try {
      _client!.subscribe(
        destination: '/topic/police.locations',
        callback: (StompFrame frame) {
          if (frame.body == null) return;
          try {
            final Map<String, dynamic> parsed = jsonDecode(frame.body!);
            _ambulanceController.add(parsed);
          } catch (e) {
            debugPrint(
              'STOMP: failed to parse incoming message: $e\n${frame.body}',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('STOMP subscribe error: $e');
    }
  }

  /// Send driver location (DTO expects {latitude, longitude})
  void sendLocation(LocationData locationData) {
    if (!isConnected()) {
      debugPrint('STOMP not connected; sendLocation skipped');
      return;
    }
    if (locationData.latitude == null || locationData.longitude == null) {
      return;
    }

    final payload = jsonEncode({
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
    });

    try {
      _client!.send(destination: '/app/driver.location', body: payload);
    } catch (e) {
      debugPrint('STOMP send error: $e');
    }
  }

  /// Graceful disconnect and stop reconnect attempts
  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    if (_client != null) {
      try {
        _client!.deactivate();
      } catch (_) {
        // ignore
      }
      _client = null;
    }
    _connectedController.add(false);
  }

  void _tryReconnect(String jwtToken) {
    if (_manuallyDisconnected) return;

    _reconnectAttempt++;
    final delaySeconds = min(30, pow(2, _reconnectAttempt).toInt());
    debugPrint(
      'STOMP reconnect attempt $_reconnectAttempt in $delaySeconds seconds',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_manuallyDisconnected) return;
      connect();
    });
  }

  Future<void> dispose() async {
    await disconnect();
    await _ambulanceController.close();
    await _connectedController.close();
  }
}
