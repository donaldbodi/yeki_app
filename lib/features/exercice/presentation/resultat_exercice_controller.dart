import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/repositories/exercice_repository.dart';

enum ResultatExerciceEtat { chargement, pret, erreur }

/// État + logique de l'écran « résultat d'exercice » (P6.5).
/// `ChangeNotifier` plutôt que `setState` (interdit sous `lib/features/`,
/// règle 7 de `check_design_system.sh`) — même patron que
/// `PasserExerciceController` (P6.4).
class ResultatExerciceController extends ChangeNotifier {
  ResultatExerciceController({
    required this.exerciceId,
    ExerciceRepository? repository,
    this.celebrationVisible = false,
  }) : _repo = repository ?? ExerciceRepository();

  final int exerciceId;
  final ExerciceRepository _repo;

  ResultatExerciceEtat etat = ResultatExerciceEtat.chargement;
  String? erreurMessage;
  ResultatExercice? resultat;

  /// Historique complet (endpoint dédié, paginé côté serveur) — chargé à
  /// la demande seulement (ouverture de la feuille « Toutes les
  /// tentatives »), distinct de `resultat.historique` qui peut être une
  /// vue tronquée aux tentatives récentes.
  List<TentativeHistorique>? historiqueComplet;
  bool chargementHistorique = false;

  /// Affichage de `YkCelebration` (dismissible) et dépliage de la
  /// correction détaillée — portés par ce contrôleur plutôt que par un
  /// `setState` local (interdit sous `lib/features/`, règle 7).
  bool celebrationVisible;
  bool correctionVisible = true;

  void masquerCelebration() {
    celebrationVisible = false;
    notifyListeners();
  }

  void basculerCorrectionVisible() {
    correctionVisible = !correctionVisible;
    notifyListeners();
  }

  Future<void> charger() async {
    etat = ResultatExerciceEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      resultat = await _repo.resultat(exerciceId);
      etat = ResultatExerciceEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ResultatExerciceEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le résultat. Vérifiez votre connexion.';
      etat = ResultatExerciceEtat.erreur;
    }
    notifyListeners();
  }

  Future<void> chargerHistoriqueComplet() async {
    if (historiqueComplet != null || chargementHistorique) return;
    chargementHistorique = true;
    notifyListeners();
    try {
      historiqueComplet = await _repo.historique(exerciceId);
    } on ApiException catch (_) {
      historiqueComplet = resultat?.historique ?? const [];
    } finally {
      chargementHistorique = false;
      notifyListeners();
    }
  }
}
