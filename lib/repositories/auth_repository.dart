import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/auth_result.dart';
import 'package:yeki/models/user_profile.dart';

/// Authentification. Tranche initiale volontairement non-exhaustive —
/// changePassword attend la migration de son écran.
class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<AuthResult> login({
    required String identifiant,
    required String password,
  }) async {
    final data = await _api.post(AccountsEndpoints.authLogin, data: {
      'identifier': identifiant,
      'password': password,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Inscription (P5.4). `parcours`/`departementId`/`niveau` obligatoires
  /// côté backend pour `userType == 'apprenant'` (CDC_BACKEND §13.2) — non
  /// envoyés pour un enseignant. Réutilise `AuthResult` (même forme de
  /// réponse `{token, role}` que login) : le token n'est pas utilisé pour
  /// une auto-connexion (décision actée, voir docs/ecarts/register.md), le
  /// flux redirige vers /login après création du compte.
  Future<AuthResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String userType,
    int? parcoursId,
    int? departementId,
    String? niveau,
  }) async {
    final data = await _api.post(AccountsEndpoints.authRegister, data: {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'user_type': userType,
      if (parcoursId != null) 'parcours': parcoursId,
      if (departementId != null) 'departement': departementId,
      if (niveau != null) 'niveau': niveau,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Étape 1/3 du flux mot de passe oublié (P5.5). Réponse générique côté
  /// backend qu'un compte existe ou non pour cet email (anti-énumération) —
  /// `debug_code` n'est présent qu'en mode `DEBUG` quand l'envoi d'email a
  /// échoué (voir docs/ecarts/forgot_password.md).
  Future<String?> forgotPassword({required String email}) async {
    final data = await _api.post(AccountsEndpoints.authForgotPassword, data: {
      'email': email,
    });
    return Map<String, dynamic>.from(data as Map)['debug_code'] as String?;
  }

  /// Étape 2/3 : vérifie le code à 6 chiffres, renvoie le jeton à usage
  /// unique nécessaire à `resetPassword`.
  Future<String> verifyOtp({required String email, required String code}) async {
    final data = await _api.post(AccountsEndpoints.authVerifyOtp, data: {
      'email': email,
      'code': code,
    });
    return Map<String, dynamic>.from(data as Map)['reset_token'] as String;
  }

  /// Étape 3/3 : applique le nouveau mot de passe. Le backend révoque tous
  /// les tokens existants de l'utilisateur — une reconnexion est requise
  /// après succès.
  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(AccountsEndpoints.authResetPassword, data: {
      'email': email,
      'reset_token': resetToken,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  Future<void> logout() async {
    await _api.post(AccountsEndpoints.authLogout);
  }

  Future<UserProfile> getCurrentUser() async {
    final data = await _api.get(AccountsEndpoints.profilMe);
    return UserProfile.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
