import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String _baseUrl = "http://10.0.2.2:8080/api/auth";
  final _storage = const FlutterSecureStorage();

  Future<(bool, String?, String?)> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final String? token = body['token'];
        final String? role = body['role']; // must be sent from backend

        if (token != null) {
          await _storage.write(key: 'jwt_token', value: token);
          return (true, role, null);
        }

        return (false, null, "No token received");
      }

      return (false, null, "Invalid credentials");

    } catch (e) {
      return (false, null, "Cannot connect to server");
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
