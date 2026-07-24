// lib/core/providers/connectivity_provider.dart
//
// Provider transverse (P3.4) : état de connectivité réseau. Ponte
// `OfflineService.isOnline` (mécanisme déjà existant, utilisé par
// `SyncService` pour gater la synchronisation) plutôt que de câbler une
// détection indépendante — `connectivity_plus` est bien en dépendance
// mais son câblage réel changerait le comportement de détection réseau
// d'`OfflineService` lui-même, un risque de régression hors périmètre de
// ce ticket Riverpod. Une seule source de vérité pour "est-on en ligne".

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/services/offline_service.dart';

class ConnectivityController extends Notifier<bool> {
  @override
  bool build() {
    OfflineService.addConnectionListener(_onConnectionChanged);
    ref.onDispose(() => OfflineService.removeConnectionListener(_onConnectionChanged));
    return OfflineService.isOnline;
  }

  void _onConnectionChanged(bool isOnline) => state = isOnline;
}

final connectivityProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);
