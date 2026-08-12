import 'package:flutter/foundation.dart';

import 'package:yeki/services/update_service.dart';

/// État + logique de l'écran « télécharger l'application ». `ChangeNotifier`
/// plutôt que `setState` (interdit sous `lib/features/`, règle 7).
class DownloadController extends ChangeNotifier {
  static const plateformes = ['android', 'ios', 'desktop'];

  bool chargement = true;
  final Map<String, UpdateInfo?> versions = {};

  Future<void> charger() async {
    final resultats = await Future.wait([
      for (final p in plateformes) UpdateService.fetchVersion(platform: p),
    ]);
    for (var i = 0; i < plateformes.length; i++) {
      versions[plateformes[i]] = resultats[i];
    }
    chargement = false;
    notifyListeners();
  }
}
