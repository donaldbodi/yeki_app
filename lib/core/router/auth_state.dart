import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/notification_repository.dart';

/// Photographie de l'état d'authentification, lue synchroniquement par
/// `guards.dart` à chaque navigation. `bootstrapped` distingue « pas
/// encore lu SharedPreferences » (→ écran splash) de « lu, utilisateur
/// déconnecté » (→ /login) : les deux ont `token == null` mais doivent
/// mener à des écrans différents.
@immutable
class YekiAuthSnapshot {
  final bool bootstrapped;
  final String? token;
  final String? role;
  final bool onboardingDone;

  const YekiAuthSnapshot({
    this.bootstrapped = false,
    this.token,
    this.role,
    this.onboardingDone = false,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  YekiAuthSnapshot copyWith({
    bool? bootstrapped,
    String? token,
    String? role,
    bool? onboardingDone,
  }) =>
      YekiAuthSnapshot(
        bootstrapped: bootstrapped ?? this.bootstrapped,
        token: token ?? this.token,
        role: role ?? this.role,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );
}

/// Source de vérité unique de l'état d'auth pour le routeur. Branché sur
/// `GoRouter(refreshListenable: authState)` : toute mise à jour de
/// `.value` déclenche automatiquement une réévaluation de `redirect`,
/// sans geste `Navigator`/`BuildContext` manuel.
class AuthStateNotifier extends ValueNotifier<YekiAuthSnapshot> {
  AuthStateNotifier() : super(const YekiAuthSnapshot());

  static const _kToken = 'token';
  static const _kRole = 'role';
  static const _kFcmToken = 'fcm_token';
  static const _kOnboarding = 'onboarding_done';
  static const _secureStorage = FlutterSecureStorage();

  /// `flutter_secure_storage` délègue à un canal de plateforme (Keychain/
  /// Keystore) : jamais garanti disponible (plateforme non supportée,
  /// trousseau corrompu, absence de mock de canal en test — voir
  /// `test/splash_page_test.dart`). Une erreur ici ne doit JAMAIS bloquer
  /// le bootstrap/la connexion : repli silencieux sur `SharedPreferences`,
  /// déjà la source de vérité avant cette migration (P5.3).
  Future<String?> _readSecureToken() async {
    try {
      return await _secureStorage.read(key: _kToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecureToken(String token) async {
    try {
      await _secureStorage.write(key: _kToken, value: token);
    } catch (_) {}
  }

  Future<void> _deleteSecureToken() async {
    try {
      await _secureStorage.delete(key: _kToken);
    } catch (_) {}
  }

  /// Lecture initiale, une seule fois au démarrage (remplace
  /// `YekiAuth.resolveStartPage`'s `FutureBuilder`). Le token est lu en
  /// priorité depuis `flutter_secure_storage` (P5.3), avec repli sur
  /// `SharedPreferences` pour les sessions ouvertes avant cette migration
  /// — voir `docs/ecarts/login.md` §5 (double-écriture transitoire, 45+
  /// fichiers dont `AuthInterceptor` lisent encore `SharedPreferences`).
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final secureToken = await _readSecureToken();
    value = YekiAuthSnapshot(
      bootstrapped: true,
      token: secureToken ?? prefs.getString(_kToken),
      role: prefs.getString(_kRole),
      onboardingDone: prefs.getBool(_kOnboarding) ?? false,
    );
  }

  Future<void> login({required String token, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeSecureToken(token);
    // Legacy, encore lu directement par 45+ fichiers (dont
    // `AuthInterceptor`) — double-écriture transitoire, voir
    // docs/ecarts/login.md §5.
    await prefs.setString(_kToken, token);
    await prefs.setString(_kRole, role);
    await prefs.setBool(_kOnboarding, true);
    value = value.copyWith(
      bootstrapped: true,
      token: token,
      role: role,
      onboardingDone: true,
    );
  }

  /// Déconnexion normale : appel best-effort à `/auth/logout/` (réutilise
  /// `AuthRepository`, P3.2 — pas de nouvel appel HTTP réécrit ici) puis
  /// nettoyage local. Les erreurs de l'appel API sont ignorées : la
  /// session locale doit être effacée même si le serveur est injoignable.
  Future<void> logout() async {
    try {
      await AuthRepository().logout();
    } on ApiException {
      // Best-effort : on efface la session locale même en cas d'échec.
    } catch (_) {}
    await clearSession();
  }

  /// Déconnexion locale uniquement (efface la session, jamais
  /// `onboarding_done`) — utilisée par [logout] ci-dessus ET par la
  /// déconnexion forcée sur 401 (`AuthInterceptor.onSessionExpired`,
  /// P3.2), qui ne doit PAS retenter un appel API déjà voué à échouer
  /// (le serveur vient de dire que le token est invalide).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Désactivation OBLIGATOIRE du jeton push côté backend (P10.3/CDC §9.2)
    // — sinon le prochain utilisateur de cet appareil reçoit les
    // notifications du précédent. Best-effort : ne doit jamais bloquer la
    // déconnexion si le réseau est indisponible.
    final fcmToken = prefs.getString(_kFcmToken);
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        await NotificationRepository().supprimerDeviceToken(fcmToken);
      } catch (_) {}
    }
    await _deleteSecureToken();
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kFcmToken);
    value = value.copyWith(bootstrapped: true, token: null, role: null);
  }

  /// Mémorise localement le jeton FCM déjà enregistré côté backend par
  /// [PushNotificationService] — nécessaire pour pouvoir le désactiver à
  /// la déconnexion (voir [clearSession]) sans redemander le jeton au SDK
  /// Firebase à ce moment-là.
  Future<void> setFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFcmToken, token);
  }

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
    value = value.copyWith(onboardingDone: true);
  }
}

/// Instance unique, importée par `main.dart`, `app_router.dart` et
/// `AuthInterceptor`.
final AuthStateNotifier authState = AuthStateNotifier();
