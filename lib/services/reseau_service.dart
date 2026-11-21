// lib/services/reseau_service.dart
//
// Suit l'état du réseau du téléphone (connectivity_plus, déjà en
// dépendance mais jamais branché) : dès que le réseau revient, les envois
// en attente partent (`OfflineService.setOnline(true)` lance la
// synchronisation), et le bandeau « hors ligne » disparaît. L'état est
// aussi mis à jour à chaque échange avec le serveur (`HorsLigneInterceptor`).

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:yeki/services/offline_service.dart';

class ReseauService {
  ReseauService._();

  static StreamSubscription<List<ConnectivityResult>>? _abonnement;

  static Future<void> demarrer() async {
    if (kIsWeb || _abonnement != null) return;
    _appliquer(await Connectivity().checkConnectivity());
    _abonnement = Connectivity().onConnectivityChanged.listen(_appliquer);
  }

  static void _appliquer(List<ConnectivityResult> etats) {
    final connecte = etats.any((e) => e != ConnectivityResult.none);
    if (connecte != OfflineService.isOnline) OfflineService.setOnline(connecte);
  }
}
