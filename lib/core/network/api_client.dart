// Point d'entrée réseau unique du projet. Tout nouveau code doit passer
// par `ApiClient` (ou un Repository construit dessus) — le paquet `http`
// est proscrit pour tout nouveau code (convention documentée, pas
// appliquée par un lint) : les 48+ fichiers qui l'utilisent encore
// directement migreront progressivement, à la refonte de leur écran.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Singleton Dio unique de l'application — une seule base URL, un seul
/// jeu d'intercepteurs. Toute exception qui en sort est une
/// [ApiException] (jamais une `DioException` brute) : les appelants n'ont
/// besoin que d'un `catch (ApiException e)`.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  static ApiClient get instance => _instance;

  late final Dio _dio;

  /// Timeout étendu pour les appels Yéki IA (LLM, plus lents) — à passer
  /// explicitement en `options` sur CE seul point d'appel, jamais au
  /// niveau global de `BaseOptions`.
  static const Duration iaTimeout = Duration(seconds: 60);

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );

    // Ordre important : Dio exécute les intercepteurs dans l'ordre de la
    // liste. Auth doit injecter l'en-tête avant l'envoi (tôt) ; Retry doit
    // voir la DioException brute avant qu'Error ne la transforme (avant
    // Error) ; Error doit être en dernier puisqu'il produit l'ApiException
    // finale.
    _dio.interceptors.addAll([
      if (kDebugMode) LoggingInterceptor(),
      AuthInterceptor(),
      RetryInterceptor(_dio),
      ErrorInterceptor(),
    ]);
  }

  String _normalize(String path) => path.startsWith('/') ? path : '/$path';

  Future<dynamic> _send(Future<Response> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.network(e.message);
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.get(
            _normalize(path),
            queryParameters: query,
            options: options,
            cancelToken: cancelToken,
          ));

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.post(
            _normalize(path),
            data: data,
            queryParameters: query,
            options: options,
            cancelToken: cancelToken,
          ));

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.put(
            _normalize(path),
            data: data,
            queryParameters: query,
            options: options,
            cancelToken: cancelToken,
          ));

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.patch(
            _normalize(path),
            data: data,
            queryParameters: query,
            options: options,
            cancelToken: cancelToken,
          ));

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.delete(
            _normalize(path),
            data: data,
            queryParameters: query,
            options: options,
            cancelToken: cancelToken,
          ));

  /// Dispatch générique par méthode HTTP (chaîne) — sert `OfflineService`/
  /// `SyncService`, qui stockent la méthode d'une action en attente comme
  /// une simple chaîne et n'ont ainsi plus besoin de leur propre `switch`.
  Future<dynamic> request(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    switch (method.toUpperCase()) {
      case 'GET':
        return get(path, query: query);
      case 'POST':
        return post(path, data: data, query: query);
      case 'PUT':
        return put(path, data: data, query: query);
      case 'PATCH':
        return patch(path, data: data, query: query);
      case 'DELETE':
        return delete(path, data: data, query: query);
      default:
        throw ArgumentError('Méthode HTTP inconnue : $method');
    }
  }

  /// Échappatoire pour le téléchargement de fichiers volumineux
  /// (`CacheManager`) : [url] doit être une URL ABSOLUE (média hors
  /// `baseUrl`, ex. Firebase Storage) — Dio ignore `baseUrl` dès que le
  /// chemin passé a déjà un schéma `http(s)`.
  Future<Response<ResponseBody>> downloadStream(
    String url, {
    CancelToken? cancelToken,
  }) {
    return _dio.get<ResponseBody>(
      url,
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );
  }
}
