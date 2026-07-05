import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'map_screen.dart';
import 'police_map_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Robust login handler:
  /// - Calls AuthService.login
  /// - Reads saved token/role
  /// - Attempts to decode JWT for role claims if needed
  /// - Normalizes role strings and navigates accordingly
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    // Call login service
    final (bool success, String? roleFromService, String? error) =
    await _authService.login(email, password);

    // read stored token / role (if AuthService saved them)
    final storedToken = await _authService.getToken();
    final storedRole = await _authService.getSavedRole();

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Debug prints - useful when things don't match expectations
    try {
      print('=== LOGIN DEBUG ===');
      print('login success: $success');
      print('roleFromService: $roleFromService');
      print('storedRole (secure storage): $storedRole');
      if (storedToken != null && storedToken.length > 20) {
        print('storedToken (prefix): ${storedToken.substring(0, 20)}...');
      } else {
        print('storedToken: $storedToken');
      }
    } catch (_) {}

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Login failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Resolve role: prefer service -> saved -> JWT claims -> fallback heuristic
    String resolvedRole = (roleFromService ?? storedRole ?? '').toString().toUpperCase();

    // If empty, try to decode the JWT for common claim names
    if (resolvedRole.isEmpty && storedToken != null) {
      final claims = _decodeJwtPayload(storedToken);
      if (claims.isNotEmpty) {
        // common keys to look for
        final candidates = ['role', 'roles', 'authorities', 'scope', 'user_role', 'roleName', 'type'];
        for (final k in candidates) {
          if (claims.containsKey(k)) {
            final v = claims[k];
            if (v is String && v.isNotEmpty) {
              resolvedRole = v.toUpperCase();
              break;
            } else if (v is List && v.isNotEmpty) {
              resolvedRole = v.first.toString().toUpperCase();
              break;
            }
          }
        }

        // sometimes role sits inside user claim
        if (resolvedRole.isEmpty && claims['user'] is Map) {
          final user = claims['user'] as Map;
          if (user['role'] != null) resolvedRole = user['role'].toString().toUpperCase();
          else if (user['roles'] is List && (user['roles'] as List).isNotEmpty) {
            resolvedRole = (user['roles'] as List).first.toString().toUpperCase();
          }
        }

        // another common key: authorities
        if (resolvedRole.isEmpty && claims['authorities'] is List && (claims['authorities'] as List).isNotEmpty) {
          resolvedRole = (claims['authorities'] as List).first.toString().toUpperCase();
        }
      }
    }

    // final fallback: use email heuristic only when role unknown
    if (resolvedRole.isEmpty) {
      if (email.toLowerCase().startsWith('police')) {
        resolvedRole = 'ROLE_POLICE';
      } else {
        resolvedRole = 'ROLE_DRIVER';
      }
    }

    print('Resolved role: $resolvedRole');

    // Navigate based on resolved role
    if (resolvedRole.contains('POLICE')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PoliceMapScreen()),
      );
    } else if (resolvedRole.contains('DRIVER')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } else {
      // fallback to driver map if unknown
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  /// Decode JWT payload (no verification) and return claims map
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      var payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      final parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) return parsed;
      return Map<String, dynamic>.from(parsed);
    } catch (e) {
      // ignore decode errors - return empty map
      print('JWT decode error: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final neonBlue = const Color(0xFF00E5FF);
    final darkBg = const Color(0xFF050814);

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // 🔵 Neon blobs background
          Positioned(
            top: -80,
            left: -60,
            child: _neonCircle(180, Colors.pinkAccent.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _neonCircle(220, neonBlue.withOpacity(0.18)),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App title
                  Text(
                    "Ambulance\nTracking System",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonBlue,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: neonBlue.withOpacity(0.7),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue as Driver / Traffic Police",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Glass / neon card
                  _buildGlassCard(neonBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(Color neonBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: neonBlue.withOpacity(0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email
            _buildNeonTextField(
              controller: _emailCtrl,
              label: "Email",
              hint: "you@example.com",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Email is required";
                }
                if (!v.contains('@')) return "Enter valid email";
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Password
            _buildNeonTextField(
              controller: _passwordCtrl,
              label: "Password",
              hint: "••••••••",
              icon: Icons.lock_outline,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Password is required";
                }
                if (v.length < 6) {
                  return "Minimum 6 characters";
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.black,
                  elevation: 10,
                  shadowColor: neonBlue.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "New here? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Create account",
                    style: TextStyle(
                      color: neonBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.22),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF00E5FF),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }

  Widget _neonCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
