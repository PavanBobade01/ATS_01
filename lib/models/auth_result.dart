// lib/models/auth_result.dart

class AuthResult {
  final bool success;
  final String? role;
  final String? token;
  final String? error;

  const AuthResult({
    required this.success,
    this.role,
    this.token,
    this.error,
  });
}
