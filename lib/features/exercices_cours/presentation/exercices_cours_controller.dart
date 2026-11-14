import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/repositories/exercice_repository.dart';

enum ExercicesCoursEtat { chargement, pret, erreur }

/// État + logique de l'onglet « Exercices » d'un cours (P6.5, refonte de
/// l'ancien `exercices_cours.dart`). `ChangeNotifier` (pas de `setState`,
/// règle 7) — même patron que `PasserExerciceController`.
///
/// Porte aussi les filtres visibles (dropdowns) : [appliquerFiltresExternes]
/// est le point d'entrée du correctif du bug de filtre — relance le
/// fetch ET resynchronise les dropdowns quand `moduleId`/`leconId`
/// changent depuis le parent (voir docs/ecarts/exercices_cours.md §3.2).
class ExercicesCoursController extends ChangeNotifier {
  ExercicesCoursController({required this.coursId, required this.canEdit, ExerciceRepository? repository})
    : _repo = repository ?? ExerciceRepository();

  final int coursId;
  final bool canEdit;
  final ExerciceRepository _repo;

  ExercicesCoursEtat etat = ExercicesCoursEtat.chargement;
  String? erreurMessage;

  List<ExerciceListItem> _exercices = const [];
  List<ModuleOption> modules = const [];

  String typeFiltre = 'all'; // all | general | module | lecon | epreuve
  int? moduleFiltre;
  int? leconFiltre;
  int etoileFiltre = 0;
  String recherche = '';

  List<ExerciceListItem> get exercices {
    final q = recherche.toLowerCase();
    return _exercices.where((ex) {
      final matchEtoile = etoileFiltre == 0 || ex.etoiles == etoileFiltre;
      final matchSearch =
          q.isEmpty || ex.titre.toLowerCase().contains(q) || ex.enonce.toLowerCase().contains(q);
      final matchType = typeFiltre == 'all'
          ? true
          : (typeFiltre == 'epreuve' ? ex.estEpreuve : ex.typeExercice == typeFiltre);
      final matchModule = moduleFiltre == null || ex.moduleId == moduleFiltre;
      final matchLecon = leconFiltre == null || ex.leconId == leconFiltre;
      return matchEtoile && matchSearch && matchType && matchModule && matchLecon;
    }).toList();
  }

  Future<void> charger({int? moduleId, int? leconId}) async {
    etat = ExercicesCoursEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      _exercices = await _repo.listerParCours(
        coursId,
        moduleId: moduleId,
        leconId: leconId,
        inclureEpreuves: canEdit,
      );
      modules = await _repo.listerModules(coursId);
      etat = ExercicesCoursEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ExercicesCoursEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger les exercices.';
      etat = ExercicesCoursEtat.erreur;
    }
    notifyListeners();
  }

  /// Point d'entrée du correctif de filtre (§B.1 du plan P6.5) — appelé
  /// depuis `didUpdateWidget` de la page quand `moduleId`/`leconId`
  /// changent (bascule d'onglet interne depuis l'onglet Leçons).
  Future<void> appliquerFiltresExternes({int? moduleId, int? leconId}) async {
    moduleFiltre = moduleId;
    leconFiltre = leconId;
    await charger(moduleId: moduleId, leconId: leconId);
  }

  void setTypeFiltre(String v) {
    typeFiltre = v;
    notifyListeners();
  }

  void setModuleFiltre(int? v) {
    moduleFiltre = v;
    leconFiltre = null;
    notifyListeners();
  }

  void setLeconFiltre(int? v) {
    leconFiltre = v;
    notifyListeners();
  }

  void setEtoileFiltre(int v) {
    etoileFiltre = v;
    notifyListeners();
  }

  void setRecherche(String v) {
    recherche = v;
    notifyListeners();
  }

  Future<bool> creerExercice({
    required String titre,
    required String enonce,
    required int etoiles,
    required int dureeMinutes,
    required int tentativesMax,
    required String typeExercice,
    int? moduleId,
    int? leconId,
    bool estEpreuve = false,
    List<int>? exercicesComposes,
  }) async {
    try {
      await _repo.creer(
        coursId: coursId,
        titre: titre,
        enonce: enonce,
        etoiles: etoiles,
        dureeMinutes: dureeMinutes,
        tentativesMax: tentativesMax,
        typeExercice: typeExercice,
        moduleId: moduleId,
        leconId: leconId,
        estEpreuve: estEpreuve,
        exercicesComposes: exercicesComposes,
      );
      await charger(moduleId: moduleFiltre, leconId: leconFiltre);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> modifierExercice({
    required int exerciceId,
    required String titre,
    required String enonce,
    required int etoiles,
    required int dureeMinutes,
    required int tentativesMax,
    required String typeExercice,
    int? moduleId,
    int? leconId,
    bool estEpreuve = false,
    List<int>? exercicesComposes,
  }) async {
    try {
      await _repo.modifier(
        exerciceId: exerciceId,
        titre: titre,
        enonce: enonce,
        etoiles: etoiles,
        dureeMinutes: dureeMinutes,
        tentativesMax: tentativesMax,
        typeExercice: typeExercice,
        moduleId: moduleId,
        leconId: leconId,
        estEpreuve: estEpreuve,
        exercicesComposes: exercicesComposes,
      );
      await charger(moduleId: moduleFiltre, leconId: leconFiltre);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerExercice(int exerciceId) async {
    try {
      await _repo.supprimer(exerciceId);
      await charger(moduleId: moduleFiltre, leconId: leconFiltre);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<QuestionExercice>> listerQuestions(int exerciceId) => _repo.listerQuestions(exerciceId);

  /// Ajoute une question. `choix` porte `est_correct` par choix pour un
  /// QCM — corrige le bug historique où aucun choix n'était jamais
  /// marqué correct côté serveur (voir docs/ecarts/exercices_cours.md).
  Future<bool> ajouterQuestion({
    required int exerciceId,
    required String text,
    required String typeQuestion,
    required double points,
    String? bonneReponse,
    List<ChoixQuestion>? choix,
  }) async {
    try {
      await _repo.ajouterQuestion(
        exerciceId: exerciceId,
        text: text,
        typeQuestion: typeQuestion,
        points: points,
        bonneReponse: bonneReponse,
        choix: choix,
      );
      // Bug corrigé : contrairement à `supprimerExercice()` (juste
      // au-dessus), cette méthode ne rappelait jamais `charger(...)` —
      // le badge "N questions" de la carte exercice restait périmé tant
      // que l'onglet n'était pas quitté/rouvert.
      await charger(moduleId: moduleFiltre, leconId: leconFiltre);
      return true;
    } catch (_) {
      return false;
    }
  }
}
