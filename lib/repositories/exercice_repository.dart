import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/exercice_models.dart';

/// Exercices — complété en P6.4 (refonte de `passer_exercice.dart`),
/// comme annoncé par le commentaire précédent de cette classe : le vrai
/// modèle (`exercice_models.dart`) est construit depuis l'usage réel de
/// cet écran, pas de façon spéculative.
class ExerciceRepository {
  final ApiClient _api;

  ExerciceRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// Démarre (ou reprend) une session de passage — crée/relit la
  /// `SessionExercice` côté serveur, source de vérité du temps restant.
  /// Lève `ApiException` (403, `isAccountInactive`/`fields` etc. non
  /// pertinents ici) si les tentatives sont déjà épuisées — à
  /// l'appelant de basculer sur `detail()` seul dans ce cas.
  Future<Map<String, dynamic>> demarrer(int exerciceId) async {
    final data = await _api.post(EvaluationEndpoints.exercicesDemarrer(exerciceId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<ExerciceAPasser> detail(int exerciceId) async {
    final data = await _api.get(EvaluationEndpoints.exercices(exerciceId));
    return ExerciceAPasser.fromDetailJson(Map<String, dynamic>.from(data as Map));
  }

  /// Soumission explicite (« Valider »). `reponses` : `{question_id: texte}`.
  Future<SoumissionExercice> evaluer(int exerciceId, Map<int, String> reponses) async {
    final data = await _api.post(
      EvaluationEndpoints.exercicesEvaluer(exerciceId),
      data: {'reponses': reponses.map((k, v) => MapEntry(k.toString(), v))},
    );
    return SoumissionExercice.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Sortie anticipée (bouton/geste système) — auto-soumission des
  /// réponses déjà fournies, voir `YkConfirmSheet`/`PopScope` de
  /// `PasserExercicePage`.
  Future<SoumissionExercice> sortir(int exerciceId, Map<int, String> reponses) async {
    final data = await _api.post(
      EvaluationEndpoints.exercicesSortir(exerciceId),
      data: {'reponses': reponses.map((k, v) => MapEntry(k.toString(), v))},
    );
    return SoumissionExercice.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ResultatExercice> resultat(int exerciceId) async {
    final data = await _api.get(EvaluationEndpoints.evaluationsExercice(exerciceId));
    return ResultatExercice.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Historique paginé de toutes les tentatives — `results` contient des
  /// objets au même format que `ResultatExercice.historique`.
  Future<List<TentativeHistorique>> historique(int exerciceId) async {
    final data = await _api.get(EvaluationEndpoints.evaluationsExerciceHistorique(exerciceId));
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((t) => TentativeHistorique.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
  }

  // ── Onglet « Exercices » d'un cours (P6.5, refonte de l'ancien
  // `exercices_cours.dart`) ────────────────────────────────────────────

  /// Liste des exercices d'un cours. `moduleId`/`leconId` filtrent côté
  /// serveur (inclut les exercices des leçons du module concerné) ;
  /// `inclureEpreuves` réservé aux rôles enseignants (le backend ignore
  /// ce paramètre pour un apprenant).
  Future<List<ExerciceListItem>> listerParCours(
    int coursId, {
    int? moduleId,
    int? leconId,
    bool inclureEpreuves = false,
  }) async {
    final query = <String, dynamic>{
      if (moduleId != null) ...{'module_id': moduleId, 'include_lesson_exercises': 'true'},
      if (leconId != null) 'lecon_id': leconId,
      if (inclureEpreuves) 'include_epreuves': 'true',
    };
    final data = await _api.get(EvaluationEndpoints.coursExercices(coursId), query: query);
    // `ListeExercicesCoursView` utilise `PaginatedListMixin` : la réponse
    // réelle est `{count, next, previous, results}`, jamais un tableau
    // brut — cast direct confirmé être la root cause de « impossible de
    // charger les exercices » (TypeError avalé par le catch générique).
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => ExerciceListItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Modules (et leurs leçons) d'un cours — alimente les dropdowns de
  /// filtre et de ciblage d'exercice.
  ///
  /// Bug corrigé : appelait `FormationEndpoints.coursModules`
  /// (`/cours/{id}/modules/`), une route qui n'accepte que `POST` côté
  /// backend (`ModuleCreateView`) — un `GET` y renvoyait systématiquement
  /// 405, faisant échouer TOUT chargement de l'onglet Exercices. Le bon
  /// endpoint (`coursListeModules`, `/cours/{id}/liste-modules/`) est
  /// déjà celui utilisé par `CoursRepository.modules()` pour l'onglet
  /// Leçons — même forme de réponse (id/titre/lecons), compatible avec
  /// `ModuleOption`/`LeconOption` ci-dessous.
  Future<List<ModuleOption>> listerModules(int coursId) async {
    final data = await _api.get(FormationEndpoints.coursListeModules(coursId));
    // Même bug que `listerParCours()` : `ModuleListByCoursView` est aussi
    // paginée, jamais un tableau brut.
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((m) => ModuleOption.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  // Rectification (demande explicite) : `enonce_image` (champ séparé)
  // retiré — l'énoncé est désormais un unique champ riche (HTML, comme
  // `EnonceDevoir.contenu`), les images éventuelles y sont insérées
  // inline par l'éditeur lui-même plutôt que via un champ fichier à part.
  Map<String, dynamic> _exerciceData({
    required String titre,
    required String enonce,
    required int etoiles,
    required int dureeMinutes,
    required int tentativesMax,
    required String typeExercice,
    int? moduleId,
    int? leconId,
    required bool estEpreuve,
    List<int>? exercicesComposes,
  }) {
    return {
      'titre': titre,
      'enonce': enonce,
      'etoiles': etoiles,
      'duree_minutes': dureeMinutes,
      'tentatives_max': tentativesMax,
      'type_exercice': typeExercice,
      'est_epreuve': estEpreuve,
      'module': moduleId,
      'lecon': leconId,
      if (estEpreuve) 'exercices_composes': exercicesComposes ?? const <int>[],
    };
  }

  Future<void> creer({
    required int coursId,
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
    await _api.post(
      EvaluationEndpoints.coursExercicesAjouter(coursId),
      data: _exerciceData(
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
      ),
    );
  }

  Future<void> modifier({
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
    await _api.patch(
      EvaluationEndpoints.exercicesModifier(exerciceId),
      data: _exerciceData(
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
      ),
    );
  }

  Future<void> supprimer(int exerciceId) async {
    await _api.delete(EvaluationEndpoints.exercicesSupprimer(exerciceId));
  }

  Future<List<QuestionExercice>> listerQuestions(int exerciceId) async {
    final data = await _api.get(EvaluationEndpoints.exercicesQuestions(exerciceId));
    final list = data as List;
    return list.map((q) => QuestionExercice.fromJson(Map<String, dynamic>.from(q as Map))).toList();
  }

  /// Ajoute une question. `choix` porte `est_correct` par choix pour un
  /// QCM (corrige le bug historique où seul un `bonne_reponse` texte
  /// était envoyé, sans jamais marquer aucun choix correct côté
  /// serveur — voir docs/ecarts/exercices_cours.md).
  Future<void> ajouterQuestion({
    required int exerciceId,
    required String text,
    required String typeQuestion,
    required double points,
    String? bonneReponse,
    List<ChoixQuestion>? choix,
  }) async {
    await _api.post(
      EvaluationEndpoints.exercicesQuestionsAjouter(exerciceId),
      data: {
        'text': text,
        'type_question': typeQuestion,
        'points': points,
        if (typeQuestion == 'qcm')
          'choix': (choix ?? const <ChoixQuestion>[]).map((c) => c.toJson()).toList()
        else
          'bonne_reponse': bonneReponse ?? '',
      },
    );
  }
}
