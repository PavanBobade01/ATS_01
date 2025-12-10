import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// AuthService improved: extracts role from several common shapes + decodes JWT if needed.
class AuthService {
  // Your Spring Boot backend base URL
  final String _baseUrl = "http://10.0.2.2:8080/api/auth";

  // Secure storage for JWT and role
  final _storage = const FlutterSecureStorage();

  /// LOGIN
  /// Returns (success, role, errorMessage)
  Future<(bool, String?, String?)> login(
      String username,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final bodyRaw = response.body;
        final body = <String, dynamic>{};
        try {
          final decoded = jsonDecode(bodyRaw);
          if (decoded is Map<String, dynamic>) {
            body.addAll(decoded);
          }
        } catch (_) {
          // response body isn't JSON or is empty — leave body empty
        }

        // Extract token: try common keys
        String? token;
        if (body.containsKey('token')) {
          token = body['token']?.toString();
        } else if (body.containsKey('accessToken')) {
          token = body['accessToken']?.toString();
        } else if (body.containsKey('authToken')) {
          token = body['authToken']?.toString();
        }

        // Some backends return token nested in 'data' or 'auth'
        if (token == null) {
          if (body['data'] is Map && body['data']['token'] != null) {
            token = body['data']['token']?.toString();
          }
          if (token == null && body['auth'] is Map && body['auth']['token'] != null) {
            token = body['auth']['token']?.toString();
          }
        }

        // Extract role from JSON if present
        String? role = _extractRoleFromBody(body);

        // If no token in JSON but perhaps token is returned as raw string (body is token)
        if (token == null) {
          final trimmed = bodyRaw.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('{')) {
            // assume body is raw token
            token = trimmed;
          }
        }

        if (token == null) {
          return (false, null, "No token received from server");
        }

        // If role still null, try to decode the JWT and look for common claim names
        if (role == null) {
          final decodedClaims = _decodeJwtPayload(token);
          role = _extractRoleFromBody(decodedClaims);
        }

        // Normalize role string (make it simple to compare)
        if (role != null) {
          role = role.toString().trim();
          // Convert arrays like ["ROLE_DRIVER"] -> "ROLE_DRIVER"
          if (role.startsWith('[') && role.endsWith(']')) {
            try {
              final list = jsonDecode(role);
              if (list is List && list.isNotEmpty) role = list.first.toString();
            } catch (_) {}
          }
        }

        // Save JWT and role
        await _storage.write(key: 'jwt_token', value: token);
        if (role != null) {
          await _storage.write(key: 'user_role', value: role);
        }

        return (true, role, null);
      }

      // Try to get better error message from backend
      String message = "Invalid credentials";
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}

      return (false, null, message);
    } catch (e) {
      return (false, null, "Cannot connect to server: $e");
    }
  }

  /// REGISTER
  Future<(bool, String?)> register(
      String username,
      String password,
      String role,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/register"),
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role, // matches your Java enum Role
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      }

      String message = "Registration failed";
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}

      return (false, message);
    } catch (e) {
      return (false, "Cannot connect to server");
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }

  Future<String?> getToken() async => _storage.read(key: 'jwt_token');

  Future<String?> getSavedRole() async => _storage.read(key: 'user_role');

  // ---------- Helpers ----------

  /// Try to extract role from a JSON-like map. Checks many common key names.
  String? _extractRoleFromBody(Map? body) {
    if (body == null) return null;

    // top level keys
    final candidates = <String>[
      'role',
      'roles',
      'authorities',
      'authority',
      'userRole',
      'user_role',
      'userRoleName',
      'type',
      'roleName'
    ];

    for (final key in candidates) {
      if (body.containsKey(key)) {
        final val = body[key];
        if (val is String && val.isNotEmpty) return val;
        if (val is List && val.isNotEmpty) return val.first.toString();
        if (val is Map && val['name'] != null) return val['name'].toString();
      }
    }

    // nested user object commonly used: { "user": { "role": "ROLE_DRIVER" } }
    if (body['user'] is Map) {
      final roleVal = _extractRoleFromBody(body['user'] as Map);
      if (roleVal != null) return roleVal;
    }

    // data object
    if (body['data'] is Map) {
      final roleVal = _extractRoleFromBody(body['data'] as Map);
      if (roleVal != null) return roleVal;
    }

    return null;
  }

  /// Decode JWT payload (no verification) and return Map of claims.
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      // Fix padding
      var normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) return parsed;
      return Map<String, dynamic>.from(parsed);
    } catch (_) {
      return {};
    }
  }
}
