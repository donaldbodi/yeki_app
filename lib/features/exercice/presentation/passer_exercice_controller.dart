import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/repositories/exercice_repository.dart';
import 'package:yeki/services/offline_service.dart';

enum PasserExerciceEtat { chargement, pret, erreur }

/// État + logique de l'écran « passer un exercice » (P6.4).
/// `ChangeNotifier` plutôt que `setState` (interdit sous `lib/features/`,
/// règle 7 de `check_design_system.sh`).
class PasserExerciceController extends ChangeNotifier {
  PasserExerciceController({required this.exerciceId, ExerciceRepository? repository})
      : _repo = repository ?? ExerciceRepository();

  final int exerciceId;
  final ExerciceRepository _repo;

  PasserExerciceEtat etat = PasserExerciceEtat.chargement;
  String? erreurMessage;

  ExerciceAPasser? exercice;
  final Map<int, String> reponses = {};
  bool tentativesEpuisees = false;
  bool soumission = false;

  /// `true` juste après un échec réseau à la soumission — les réponses
  /// restent sauvegardées localement (déjà fait en continu), la
  /// tentative n'est PAS perdue (exigence explicite du ticket).
  bool horsLigne = false;

  Timer? _debounceDraft;

  Future<void> charger() async {
    etat = PasserExerciceEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic>? demarrage;
      try {
        demarrage = await _repo.demarrer(exerciceId);
      } on ApiException catch (e) {
        // 403 recouvre 2 cas distincts côté backend : tentatives épuisées
        // (corps `{tentatives_epuisees: true, ...}`, hors enveloppe
        // standard) et accès Premium refusé (`AccesMatricePermission`,
        // aucune clé `tentatives_epuisees`) — ne pas les confondre, sinon
        // un apprenant non-Premium voit à tort « tentatives épuisées ».
        if (e.statusCode == 403 && e.fields['tentatives_epuisees'] == true) {
          tentativesEpuisees = true;
        } else {
          rethrow;
        }
      }

      final detail = await _repo.detail(exerciceId);
      exercice = demarrage != null
          ? detail.copyWith(
              dureeTotaleSecondes: (demarrage['duree_totale'] as num?)?.toInt(),
              tempsRestantSecondes: (demarrage['temps_restant'] as num?)?.toInt(),
            )
          : detail;
      tentativesEpuisees = tentativesEpuisees || exercice!.tentativesEpuisees;

      // Restaure un brouillon local si on peut encore répondre — une
      // coupure réseau pendant la saisie ne doit pas coûter une tentative.
      if (!tentativesEpuisees) {
        final brouillon = OfflineService.getExerciceDraft(exerciceId);
        if (brouillon != null) reponses.addAll(brouillon);
      }

      etat = PasserExerciceEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = PasserExerciceEtat.erreur;
    } catch (e) {
      debugPrint('PasserExerciceController.charger() — exception non-ApiException : ${e.runtimeType} : $e');
      erreurMessage = "Impossible de charger l'exercice. Vérifiez votre connexion.";
      etat = PasserExerciceEtat.erreur;
    }
    notifyListeners();
  }

  void repondre(int questionId, String valeur) {
    reponses[questionId] = valeur;
    notifyListeners();

    // Sauvegarde locale debouncée — voir docstring de `horsLigne`.
    _debounceDraft?.cancel();
    _debounceDraft = Timer(const Duration(milliseconds: 500), () {
      OfflineService.saveExerciceDraft(exerciceId, reponses);
    });
  }

  bool get toutesRepondues =>
      exercice == null || exercice!.questions.isEmpty || reponses.length >= exercice!.questions.length;

  /// Soumission explicite (« Terminer l'examen »). `auto` = déclenchée
  /// par l'expiration du minuteur (`YkCountdown.onExpired`) — pas de
  /// blocage sur "tentatives épuisées" dans ce cas (déjà géré côté
  /// serveur, P6.3 : réponse 200 sans effet plutôt qu'un rejet).
  Future<SoumissionExercice?> soumettre({bool auto = false}) async {
    if (soumission) return null;
    soumission = true;
    horsLigne = false;
    notifyListeners();

    try {
      final resultat = await _repo.evaluer(exerciceId, reponses);
      await OfflineService.clearExerciceDraft(exerciceId);
      return resultat;
    } on ApiException catch (_) {
      // Coupure réseau (ou autre échec) : le brouillon est déjà
      // sauvegardé en continu (`repondre`) — la tentative n'est pas
      // perdue, l'apprenant pourra réessayer.
      horsLigne = true;
      return null;
    } finally {
      soumission = false;
      notifyListeners();
    }
  }

  /// Sortie anticipée (bouton retour / geste système), déclenchée après
  /// confirmation via `YkConfirmSheet` — voir `PasserExercicePage`.
  Future<SoumissionExercice?> sortir() async {
    try {
      final resultat = await _repo.sortir(exerciceId, reponses);
      await OfflineService.clearExerciceDraft(exerciceId);
      return resultat;
    } on ApiException catch (_) {
      horsLigne = true;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _debounceDraft?.cancel();
    super.dispose();
  }
}
