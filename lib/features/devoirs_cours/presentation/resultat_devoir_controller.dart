import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';

enum ResultatDevoirEtat { chargement, pret, enAttenteCorrection, erreur }

/// État + logique de l'écran « résultat de devoir » (P7.6), sur le
/// patron de `ResultatExerciceController` (P6.5). `ChangeNotifier`
/// plutôt que `setState` (interdit sous `lib/features/`, règle 7).
class ResultatDevoirController extends ChangeNotifier {
  ResultatDevoirController({required this.devoirId, DevoirRepository? repository})
    : _repo = repository ?? DevoirRepository();

  final int devoirId;
  final DevoirRepository _repo;

  ResultatDevoirEtat etat = ResultatDevoirEtat.chargement;
  String? erreurMessage;
  ResultatDevoir? resultat;

  /// Dépliage de la correction détaillée — porté par ce contrôleur
  /// plutôt que par un `setState` local (interdit sous `lib/features/`,
  /// règle 7). Même patron que `ResultatExerciceController`.
  bool correctionVisible = true;

  void basculerCorrectionVisible() {
    correctionVisible = !correctionVisible;
    notifyListeners();
  }

  Future<void> charger() async {
    etat = ResultatDevoirEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      final data = await _repo.resultat(devoirId);

      // `devoir_titre` n'existe QUE dans la forme 200 complète
      // (`SoumissionResultatSerializer`) — la forme 202 « en attente de
      // correction » n'a que `{'detail': '...'}` (voir
      // `DevoirRepository.resultat`).
      if (!data.containsKey('devoir_titre')) {
        erreurMessage = data['detail'] as String?;
        etat = ResultatDevoirEtat.enAttenteCorrection;
        notifyListeners();
        return;
      }

      final r = ResultatDevoir.fromJson(data);

      // Piège backend réel (`ResultatDevoirView`) : un devoir en
      // correction MANUELLE soumis en retard (`statut == 'en_retard'`)
      // renvoie 200 avec `note: null` au lieu d'un 202 — traité ici comme
      // toujours en attente, plutôt que d'afficher un résultat sans note.
      if (r.note == null) {
        resultat = r;
        erreurMessage = 'Résultat en attente de correction par l\'enseignant.';
        etat = ResultatDevoirEtat.enAttenteCorrection;
        notifyListeners();
        return;
      }

      resultat = r;
      etat = ResultatDevoirEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ResultatDevoirEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le résultat. Vérifiez votre connexion.';
      etat = ResultatDevoirEtat.erreur;
    }
    notifyListeners();
  }
}
