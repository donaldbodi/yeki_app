import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Dernier intercepteur de la chaîne : transforme toute `DioException`
/// restante en `ApiException`, pour que les appelants n'aient jamais à
/// connaître Dio directement.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ApiException apiException;

    final response = err.response;
    if (response != null) {
      final data = response.data;
      apiException = data is Map
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
    } else if (err.type == DioExceptionType.cancel) {
      apiException = ApiException.cancelled();
    } else {
      // Aucune réponse du tout : timeout, pas de réseau, DNS...
      apiException = ApiException.network(err.message);
    }

    handler.reject(err.copyWith(error: apiException));
  }
}
