import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // Default role
  String _selectedRole = "ROLE_DRIVER";

  final List<Map<String, String>> _roles = const [
    {
      "label": "Ambulance Driver",
      "value": "ROLE_DRIVER",
    },
    {
      "label": "Traffic Police",
      "value": "ROLE_POLICE",
    },
    {
      "label": "Citizen / User",
      "value": "ROLE_USER",
    },
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final (bool success, String? error) =
    await _authService.register(email, password, _selectedRole);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Registration failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration successful! Please login."),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonPurple = const Color(0xFFB388FF);
    final darkBg = const Color(0xFF050814);

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Background neon blobs
          Positioned(
            top: -70,
            right: -60,
            child: _neonCircle(170, neonPurple.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _neonCircle(230, Colors.cyanAccent.withOpacity(0.2)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Create Account",
                    style: TextStyle(
                      color: neonPurple,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: neonPurple.withOpacity(0.7),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Register as Driver, Traffic Police, or User",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 26),

                  _buildGlassCard(neonPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(Color neonPurple) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: neonPurple.withOpacity(0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withOpacity(0.35),
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
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            _buildNeonTextField(
              controller: _confirmCtrl,
              label: "Confirm Password",
              hint: "••••••••",
              icon: Icons.lock_person_outlined,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Confirm password";
                }
                if (v != _passwordCtrl.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Role dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Registering as",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF090C1C),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: _roles.map((r) {
                    return DropdownMenuItem<String>(
                      value: r["value"],
                      child: Text(
                        r["label"]!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedRole = val;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonPurple,
                  foregroundColor: Colors.black,
                  elevation: 10,
                  shadowColor: neonPurple.withOpacity(0.8),
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
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text(
                  "Register",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                          (_) => false,
                    );
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: neonPurple,
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
            color: Color(0xFFB388FF),
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
