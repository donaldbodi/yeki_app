import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
