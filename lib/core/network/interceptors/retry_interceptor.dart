import 'dart:io';

import 'package:dio/dio.dart';

/// Retente automatiquement les échecs de transport pur (pas de réponse
/// HTTP du tout — timeout de connexion, erreur socket) sur les requêtes
/// GET uniquement. Ne retente JAMAIS POST/PUT/PATCH/DELETE (éviter un
/// double effet de bord, ex. double débit de portefeuille sur un
/// paiement retenté) ni aucune erreur 4xx (dont fait partie 429/THROTTLED,
/// dont le `retry_after` doit être traité explicitement par l'appelant,
/// pas retenté à l'aveugle).
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 2;
  static const List<Duration> _backoff = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 1200),
  ];

  RetryInterceptor(this._dio);

  bool _isTransientTransportFailure(DioException err) {
    if (err.response != null) return false; // le serveur a répondu (4xx/5xx)
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.unknown:
        return err.error is SocketException;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isGet = err.requestOptions.method.toUpperCase() == 'GET';
    if (!isGet || !_isTransientTransportFailure(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra['retry_count'] as int?) ?? 0;
    if (retryCount >= _maxRetries) {
      handler.next(err);
      return;
    }

    await Future.delayed(_backoff[retryCount]);
    try {
      final options = err.requestOptions;
      options.extra['retry_count'] = retryCount + 1;
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
