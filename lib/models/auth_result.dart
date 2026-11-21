/// Résultat d'une connexion réussie (`AuthRepository.login`).
class AuthResult {
  final String token;
  final String role;

  const AuthResult({required this.token, required this.role});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );
}
