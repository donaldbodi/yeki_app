import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';
import 'package:yeki/services/offline_service.dart';

enum ComposerDevoirEtat { chargement, pret, dejaSoumis, erreur }

/// État + logique de l'écran « composer un devoir » (P7.5), sur le
/// patron de `PasserExerciceController` (P6.4). `ChangeNotifier` plutôt
/// que `setState` (interdit sous `lib/features/`, règle 7 de
/// `check_design_system.sh`).
class ComposerDevoirController extends ChangeNotifier {
  ComposerDevoirController({required this.devoirId, DevoirRepository? repository})
    : _repo = repository ?? DevoirRepository();

  final int devoirId;
  final DevoirRepository _repo;

  ComposerDevoirEtat etat = ComposerDevoirEtat.chargement;
  String? erreurMessage;

  DevoirAComposer? devoir;
  int tempsRestantSecondes = 0;
  final Map<int, String> reponses = {};
  bool soumission = false;

  /// `true` juste après un échec réseau — les réponses restent
  /// sauvegardées localement (déjà fait en continu), la tentative n'est
  /// PAS perdue.
  bool horsLigne = false;

  Timer? _debounceDraft;

  Future<void> charger() async {
    etat = ComposerDevoirEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      try {
        tempsRestantSecondes = await _repo.demarrer(devoirId);
      } on ApiException catch (e) {
        // Seul cas de 400 sur cet endpoint : « Vous avez déjà soumis ce
        // devoir. » (`DemarrerDevoirView`) — rediriger vers le résultat
        // plutôt que d'afficher un formulaire de composition vide.
        if (e.statusCode == 400) {
          etat = ComposerDevoirEtat.dejaSoumis;
          notifyListeners();
          return;
        }
        rethrow;
      }

      devoir = await _repo.getDetail(devoirId);

      final brouillon = OfflineService.getDevoirDraft(devoirId);
      if (brouillon != null) reponses.addAll(brouillon);

      etat = ComposerDevoirEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ComposerDevoirEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le devoir. Vérifiez votre connexion.';
      etat = ComposerDevoirEtat.erreur;
    }
    notifyListeners();
  }

  void repondre(int questionId, String valeur) {
    reponses[questionId] = valeur;
    notifyListeners();

    _debounceDraft?.cancel();
    _debounceDraft = Timer(const Duration(milliseconds: 500), () {
      OfflineService.saveDevoirDraft(devoirId, reponses);
    });
  }

  /// Clés converties en chaînes — l'API attend `{"<question_id>": "..."}`.
  Map<String, dynamic> get _reponsesJson => reponses.map((k, v) => MapEntry(k.toString(), v));

  bool get toutesRepondues =>
      devoir == null ||
      devoir!.toutesLesQuestions.isEmpty ||
      reponses.length >= devoir!.toutesLesQuestions.length;

  /// `true` si la PROCHAINE sortie (bouton retour / geste système)
  /// épuisera les sorties tolérées — détermine la politique
  /// d'avertissement à afficher AVANT d'appeler le serveur (c'est
  /// `SortirDevoirView` qui décide seul, via son propre compteur, s'il
  /// s'agit d'un simple comptage ou d'une soumission automatique).
  bool get sortieEpuiseraLesTentatives =>
      devoir != null && (devoir!.nbSorties + 1) >= devoir!.tentativesMax;

  /// Sortie anticipée — contrairement à l'exercice (P6.4, sortie libre si
  /// tentatives épuisées), TOUJOURS appelée pour le devoir : c'est le
  /// serveur qui décide s'il s'agit d'un comptage ou d'une soumission
  /// automatique en l'état.
  Future<Map<String, dynamic>?> sortir() async {
    try {
      final resultat = await _repo.sortir(devoirId, _reponsesJson);
      await OfflineService.clearDevoirDraft(devoirId);
      return resultat;
    } on ApiException catch (_) {
      horsLigne = true;
      notifyListeners();
      return null;
    }
  }

  /// Soumission explicite (bouton « Soumettre ») ou automatique
  /// (expiration du `YkCountdown`) — jamais liée à la politique de
  /// sortie ci-dessus.
  Future<Map<String, dynamic>?> soumettre({bool auto = false}) async {
    if (soumission) return null;
    soumission = true;
    horsLigne = false;
    notifyListeners();

    try {
      final resultat = await _repo.soumettre(devoirId, _reponsesJson);
      await OfflineService.clearDevoirDraft(devoirId);
      return resultat;
    } on ApiException catch (_) {
      horsLigne = true;
      return null;
    } finally {
      soumission = false;
      notifyListeners();
    }
  }

  /// Fire-and-forget — anti-triche uniquement, aucun impact sur le
  /// déroulé de la composition (généralisé à tous les devoirs, P7.5).
  Future<void> signalerFocusPerdu() async {
    try {
      await _repo.signalerFocusPerdu(devoirId);
    } on ApiException catch (_) {
      // Signal best-effort — une perte de connexion ne doit jamais
      // perturber la composition en cours.
    }
  }

  @override
  void dispose() {
    _debounceDraft?.cancel();
    super.dispose();
  }
}
