import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'map_screen.dart';
import 'police_map_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final (bool success, String? role, String? error) =
    await _authService.login(username, password);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // Debug print to verify backend role
      // ignore: avoid_print
      print("Logged in as: $username, role from backend = $role");

      // ✅ Backend role check
      if (role == "POLICE" || role == "TRAFFIC_POLICE") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PoliceMapScreen()),
        );

        // ✅ Fallback for demo / testing
      } else if (username.toLowerCase().startsWith("police")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PoliceMapScreen()),
        );

        // ✅ Default = Ambulance driver
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ambulance Tracking System Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleLogin,
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
