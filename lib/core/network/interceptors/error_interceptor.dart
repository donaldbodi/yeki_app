import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../api_exception.dart';

/// Dernier intercepteur de la chaîne : transforme toute `DioException`
/// restante en `ApiException`, pour que les appelants n'aient jamais à
/// connaître Dio directement.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err.copyWith(error: _toApiException(err)));
  }

  ApiException _toApiException(DioException err) {
    try {
      final response = err.response;
      if (response != null) {
        final data = response.data;
        return data is Map
            ? ApiException.fromEnvelope(
                Map<String, dynamic>.from(data),
                statusCode: response.statusCode ?? 0,
              )
            : ApiException(
                code: ApiErrorCodes.serverError,
                message: 'Erreur serveur (${response.statusCode}).',
                fields: const {},
                statusCode: response.statusCode,
              );
      }
      if (err.type == DioExceptionType.cancel) return ApiException.cancelled();
      // Aucune réponse du tout : timeout, pas de réseau, DNS...
      return ApiException.network(err.message);
    } catch (e) {
      // Filet de sécurité absolu : quelle que soit la forme réelle de la
      // réponse serveur (corps inattendu, page d'erreur d'un proxy, cas
      // non prévu par `ApiException.fromEnvelope`), CETTE méthode ne doit
      // JAMAIS laisser fuir une exception brute (ex. `TypeError` de cast)
      // vers l'appelant — l'app entière repose sur la garantie « toute
      // erreur réseau devient une ApiException », documentée en tête de
      // `ApiClient`. Un échec de conversion devient lui-même une
      // ApiException plutôt que de casser cette garantie.
      debugPrint(
        'ErrorInterceptor — échec de conversion en ApiException : '
        '${e.runtimeType} : $e | statusCode=${err.response?.statusCode} '
        '| dataType=${err.response?.data.runtimeType} | data=${err.response?.data}',
      );
      return ApiException(
        code: ApiErrorCodes.serverError,
        message: 'Erreur serveur (${err.response?.statusCode ?? 0}).',
        fields: const {},
        statusCode: err.response?.statusCode,
      );
    }
  }
}
