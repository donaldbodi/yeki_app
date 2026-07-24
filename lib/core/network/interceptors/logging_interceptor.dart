import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Journalise les requêtes/réponses en console, uniquement en debug
/// (n'est ajouté à la chaîne d'intercepteurs que `if (kDebugMode)` — voir
/// `api_client.dart`). Ne journalise JAMAIS le token en clair, même en
/// debug : l'en-tête `Authorization` est systématiquement masqué, ainsi
/// que toute clé `token` dans le corps de la réponse (ex. `/auth/login/`,
/// migré vers `ApiClient` en P5.3 — voir `docs/ecarts/login.md` §6).
class LoggingInterceptor extends Interceptor {
  Map<String, dynamic> _redact(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = 'Token ***REDACTED***';
    }
    return copy;
  }

  dynamic _redactBody(dynamic data) {
    if (data is Map && data.containsKey('token')) {
      final copy = Map<String, dynamic>.from(data);
      copy['token'] = '***REDACTED***';
      return copy;
    }
    return data;
  }

  String _truncate(String s, [int max = 500]) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri} '
          'headers=${_redact(options.headers)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri} '
          '— ${_truncate(_redactBody(response.data).toString())}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
          '— ${err.type} ${err.message}');
    }
    handler.next(err);
  }
}
