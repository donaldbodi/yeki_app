import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/core/constants/api_constants.dart';

/// Injecte l'en-tête d'authentification sur chaque requête et réagit à un
/// 401 (token invalide/révoqué). Lit le token depuis `SharedPreferences`,
/// clé `'token'` — exactement la même clé que 45+ fichiers non encore
/// migrés. Depuis P5.3, `authState.login()` écrit le token À LA FOIS dans
/// `flutter_secure_storage` (source de vérité pour `authState.bootstrap()`)
/// ET ici, en `SharedPreferences` (double-écriture transitoire, le temps
/// de migrer ces 45+ fichiers dans un futur ticket dédié — voir
/// `docs/ecarts/login.md` §5) : cet intercepteur continue donc de
/// fonctionner sans modification tant que cette double-écriture existe.
class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'token';

  /// Callback statique enregistré une fois au démarrage de l'app
  /// (`main.dart`) pour effectuer la déconnexion — l'intercepteur n'a
  /// accès à aucun `BuildContext`.
  static Future<void> Function()? onSessionExpired;

  static final Uri _apiHost = Uri.parse(ApiConstants.baseUrl);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bug corrigé (piste la plus solide trouvée pour « impossible de
    // charger le PDF ») : `ApiClient.downloadStream()` sert aussi à
    // télécharger des médias HORS `baseUrl` (Firebase Storage/GCS —
    // voir son propre commentaire de tête), sur un Dio PARTAGÉ avec
    // toutes les requêtes API. Sans cette garde, notre propre jeton
    // `Authorization: Token ...` était envoyé à `storage.googleapis.com`
    // — Google Cloud Storage traite tout `Authorization` non reconnu
    // comme une tentative d'accès authentifié invalide (401/403), MÊME
    // si l'objet est public en lecture (`allUsers`). N'attacher le
    // jeton qu'aux requêtes visant réellement notre propre backend.
    if (options.uri.host != _apiHost.host) {
      handler.next(options);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Token $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Point d'extension : le backend n'a aujourd'hui ni expiration de
      // token ni endpoint de rafraîchissement (TokenAuthentication DRF
      // statique) — cette méthode est un no-op assumé. Le jour où un
      // vrai refresh existera côté backend, seule cette méthode change ;
      // aucun appelant n'a besoin d'être retouché.
      final refreshed = await attemptTokenRefresh();
      if (!refreshed) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await onSessionExpired?.call();
      }
    }
    handler.next(err);
  }

  /// TODO(auth-refresh) : no-op tant qu'aucun endpoint de rafraîchissement
  /// n'existe côté backend. Renvoie toujours `false` aujourd'hui.
  Future<bool> attemptTokenRefresh() async => false;
}
