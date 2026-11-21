// lib/core/network/interceptors/hors_ligne_interceptor.dart
//
// Mode hors ligne « comme WhatsApp » (mobile uniquement) :
// - toute réponse GET reçue est gardée sur le téléphone (`CacheApiService`) ;
//   sans réseau, la dernière réponse connue est resservie, et l'écran
//   s'affiche comme d'habitude avec ces données ;
// - sans réseau, les envois de l'apprenant (réponses d'exercice et de
//   devoir, question ou réponse du forum) sont mis en file d'attente
//   (`OfflineService.addPendingAction`, file persistante déjà existante) et
//   partent tout seuls au retour de la connexion ; l'appelant reçoit
//   `ApiException.enAttente()` pour l'indiquer à l'utilisateur.
// L'état « en ligne / hors ligne » est mis à jour à chaque échange.
//
// Placé AVANT `ErrorInterceptor` (qui termine la chaîne en rejetant), et
// après `RetryInterceptor` (les nouvelles tentatives passent d'abord).

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:yeki/services/cache_api_service.dart';
import 'package:yeki/services/offline_service.dart';

import '../api_exception.dart';

class HorsLigneInterceptor extends Interceptor {
  /// Marqueur posé par `OfflineService` sur le renvoi d'une action en
  /// attente : un échec n'est alors pas remis une deuxième fois en file.
  static const sansFileAttente = 'yeki_sans_file_attente';

  /// Envois mis en file d'attente sans réseau.
  static final _envoisEnAttente = [
    RegExp(r'^/exercices/\d+/(evaluer|sortir)/$'),
    RegExp(r'^/devoirs/\d+/(soumettre|sortir)/$'),
    RegExp(r'^/forum/questions/$'),
    RegExp(r'^/forum/questions/\d+/repondre/$'),
  ];

  /// Jamais gardées : authentification (jetons) et statut de paiement en direct.
  static final _nonMisEnCache = [RegExp(r'^/auth/'), RegExp(r'^/paiements/')];

  static String _chemin(RequestOptions o) => o.uri.path.replaceFirst(RegExp(r'^/api'), '');

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kIsWeb) {
      if (!OfflineService.isOnline) OfflineService.setOnline(true);
      final o = response.requestOptions;
      final chemin = _chemin(o);
      if (o.method == 'GET' &&
          (response.statusCode ?? 0) < 300 &&
          !_nonMisEnCache.any((r) => r.hasMatch(chemin))) {
        CacheApiService.enregistrer(CacheApiService.cle(chemin, o.queryParameters), response.data);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kIsWeb || !_estCoupureReseau(err)) {
      if (err.response != null && !kIsWeb && !OfflineService.isOnline) OfflineService.setOnline(true);
      return handler.next(err);
    }
    if (OfflineService.isOnline) OfflineService.setOnline(false);

    final o = err.requestOptions;
    final chemin = _chemin(o);

    if (o.method == 'GET') {
      final enCache = CacheApiService.lire(CacheApiService.cle(chemin, o.queryParameters));
      if (enCache != null) {
        return handler.resolve(
          Response(requestOptions: o, data: enCache, statusCode: 200, extra: {'hors_ligne': true}),
        );
      }
      return handler.next(err);
    }

    final data = o.data;
    if (o.extra[sansFileAttente] != true &&
        data is Map &&
        _envoisEnAttente.any((r) => r.hasMatch(chemin))) {
      OfflineService.addPendingAction(
        endpoint: chemin,
        data: Map<String, dynamic>.from(data),
        method: o.method,
      );
      return handler.reject(err.copyWith(error: ApiException.enAttente()));
    }
    handler.next(err);
  }

  /// Le serveur n'a jamais répondu : pas de réseau, délai dépassé, DNS.
  static bool _estCoupureReseau(DioException err) {
    if (err.response != null) return false;
    return const {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.unknown,
    }.contains(err.type);
  }
}
