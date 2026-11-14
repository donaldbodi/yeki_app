import 'package:dio/dio.dart' show FormData, MultipartFile;

import 'package:yeki/core/design/components/inputs/yk_file_upload.dart';
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/views/pages/apprenants/devoir_models.dart' show DevoirItem;

/// Devoirs. `listMine` (P11.2) réutilise désormais `DevoirItem`
/// (déménagé dans `views/pages/apprenants/devoir_models.dart`, pour que ce
/// repository puisse l'importer sans dépendre de `devoirs_page.dart` —
/// modèle réellement éprouvé en production (`statutApprenant`,
/// `noteApprenant`, cache hors-ligne). L'ancien `DevoirModel`/
/// `OlympiadeInfo` du même fichier étaient du code mort, retirés.
/// `getDetail`/`demarrer`/`sortir`/`signalerFocusPerdu` (P7.5, écran de
/// composition) utilisent `DevoirAComposer` (`lib/models/devoir_models.dart`).
/// P7.4 complète avec la gestion enseignant (liste par cours,
/// création/édition, duplication/publication, énoncés, questions,
/// soumissions/correction), sur le patron de `ExerciceRepository` (P6.5).
class DevoirRepository {
  final ApiClient _api;

  DevoirRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<DevoirItem>> listMine() async {
    final data = await _api.get(EvaluationEndpoints.devoirs);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => DevoirItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<DevoirAComposer> getDetail(int devoirId) async {
    final data = await _api.get(EvaluationEndpoints.devoirsDetail(devoirId));
    return DevoirAComposer.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Résultat d'un devoir déjà soumis. Brut (pas de modèle unique) car
  /// deux formes distinctes partagent le même code HTTP 200 côté client :
  /// `ApiClient`/Dio n'accepte pas seulement 200 mais toute la plage
  /// 200-299 comme un succès (`validateStatus` par défaut), donc un 202
  /// « en attente de correction » (`{'detail': '...'}`) arrive ICI comme
  /// une réponse normale, pas comme une `ApiException` — seul un vrai 404
  /// (devoir encore en cours / résultat indisponible) lève une exception.
  /// L'appelant distingue les deux formes par la présence de la clé
  /// `devoir_titre` (voir `ResultatDevoirController`).
  Future<Map<String, dynamic>> resultat(int devoirId) async {
    final data = await _api.get(EvaluationEndpoints.devoirsResultat(devoirId));
    return Map<String, dynamic>.from(data as Map);
  }

  /// Démarre (ou reprend) la composition — crée la `SoumissionDevoir` côté
  /// serveur si besoin. Renvoie le temps restant en secondes ; `0` dans le
  /// cas marginal où le serveur a soumis automatiquement à l'entrée (sorties
  /// déjà épuisées avant même ce chargement — `soumission` est alors absent
  /// de la réponse, voir `DemarrerDevoirView`).
  Future<int> demarrer(int devoirId) async {
    final data = Map<String, dynamic>.from(
      await _api.post(EvaluationEndpoints.devoirsDemarrer(devoirId)) as Map,
    );
    return (data['temps_restant_secondes'] as num?)?.toInt() ?? 0;
  }

  /// Sortie anticipée (bouton retour / geste système) — TOUJOURS appelée
  /// quand l'apprenant confirme vouloir quitter, contrairement à
  /// l'exercice (P6.4 : tentatives épuisées → sortie libre, aucun appel).
  /// Le serveur décide seul, via le compteur `sorties` qu'il vient
  /// d'incrémenter, s'il s'agit d'un simple comptage (`force_submit:
  /// false`) ou d'une soumission automatique en l'état
  /// (`force_submit: true`) — voir `SortirDevoirView`. Pas de modèle
  /// typé unique ici, cohérent avec `soumettre()` ci-dessous.
  Future<Map<String, dynamic>> sortir(
    int devoirId,
    Map<String, dynamic> reponses,
  ) async {
    final data = await _api.post(
      EvaluationEndpoints.devoirsSortir(devoirId),
      data: {'reponses': reponses},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Renvoie la réponse brute (pas de modèle typé unique aujourd'hui —
  /// cohérent avec ce que `SyncService.submitDevoir` suppose déjà).
  Future<Map<String, dynamic>> soumettre(
    int devoirId,
    Map<String, dynamic> reponses,
  ) async {
    final data = await _api.post(
      EvaluationEndpoints.devoirsSoumettre(devoirId),
      data: {'reponses': reponses},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Signale une perte de focus applicative (app mise en arrière-plan
  /// pendant la composition) — anti-triche (`nb_focus_perdu`,
  /// `est_suspecte` après 5 pertes côté serveur). Généralisé à TOUS les
  /// devoirs (P7.5) : l'ancien écran ne l'appelait que pour les devoirs
  /// d'olympiade, via un indicateur (`data['olympiade']`) que
  /// `DevoirDetailSerializer` ne renvoie en réalité jamais — signalement
  /// mort pour 100 % des devoirs réels avant ce ticket.
  Future<Map<String, dynamic>> signalerFocusPerdu(int devoirId) async {
    final data = await _api.post(EvaluationEndpoints.devoirsFocusPerdu(devoirId));
    return Map<String, dynamic>.from(data as Map);
  }

  // ── Gestion enseignant (P7.4) ────────────────────────────────────────

  Future<List<DevoirListItem>> listerParCours(int coursId) async {
    final data = await _api.get(EvaluationEndpoints.coursDevoirs(coursId));
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((d) => DevoirListItem.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList();
  }

  FormData _devoirFormData({
    String? titre,
    String? description,
    String? enonce,
    DateTime? dateDebut,
    DateTime? dateLimite,
    int? dureeMinutes,
    double? noteSur,
    double? coefficient,
    int? tentativesMax,
    String? typeCorrection,
    YkPickedFile? fichierCorrection,
  }) {
    return FormData.fromMap({
      if (titre != null) 'titre': titre,
      if (description != null) 'description': description,
      if (enonce != null) 'enonce': enonce,
      if (dateDebut != null) 'date_debut': dateDebut.toIso8601String(),
      if (dateLimite != null) 'date_limite': dateLimite.toIso8601String(),
      if (dureeMinutes != null) 'duree_minutes': dureeMinutes.toString(),
      if (noteSur != null) 'note_sur': noteSur.toString(),
      if (coefficient != null) 'coefficient': coefficient.toString(),
      if (tentativesMax != null) 'tentatives_max': tentativesMax.toString(),
      if (typeCorrection != null) 'type_correction': typeCorrection,
      if (fichierCorrection != null)
        'fichier_correction': MultipartFile.fromBytes(
          fichierCorrection.bytes,
          filename: fichierCorrection.name,
        ),
    });
  }

  /// Crée un devoir — `enonce` devient le 1er `EnonceDevoir` (ordre=1),
  /// créé automatiquement côté serveur ; les énoncés suivants s'ajoutent
  /// après création via [ajouterEnonce] (P7.1 : « un énoncé a plusieurs
  /// questions, CES questions » — le mécanisme legacy
  /// `enonces_supplementaires`, liste de chaînes brutes sans questions
  /// propres, n'est plus utilisé côté frontend).
  Future<int> creer({
    required int coursId,
    required String titre,
    String description = '',
    required String enonce,
    required DateTime dateDebut,
    required DateTime dateLimite,
    int dureeMinutes = 60,
    double noteSur = 20,
    double coefficient = 1.0,
    int tentativesMax = 1,
    required String typeCorrection,
    YkPickedFile? fichierCorrection,
  }) async {
    final data = await _api.post(
      EvaluationEndpoints.coursDevoirsCreer(coursId),
      data: _devoirFormData(
        titre: titre,
        description: description,
        enonce: enonce,
        dateDebut: dateDebut,
        dateLimite: dateLimite,
        dureeMinutes: dureeMinutes,
        noteSur: noteSur,
        coefficient: coefficient,
        tentativesMax: tentativesMax,
        typeCorrection: typeCorrection,
        fichierCorrection: fichierCorrection,
      ),
    );
    return Map<String, dynamic>.from(data as Map)['id'] as int;
  }

  Future<void> modifier({
    required int devoirId,
    String? titre,
    String? description,
    String? enonce,
    DateTime? dateDebut,
    DateTime? dateLimite,
    int? dureeMinutes,
    double? noteSur,
    double? coefficient,
    int? tentativesMax,
    String? typeCorrection,
    YkPickedFile? fichierCorrection,
  }) async {
    await _api.patch(
      EvaluationEndpoints.devoirsModifier(devoirId),
      data: _devoirFormData(
        titre: titre,
        description: description,
        enonce: enonce,
        dateDebut: dateDebut,
        dateLimite: dateLimite,
        dureeMinutes: dureeMinutes,
        noteSur: noteSur,
        coefficient: coefficient,
        tentativesMax: tentativesMax,
        typeCorrection: typeCorrection,
        fichierCorrection: fichierCorrection,
      ),
    );
  }

  /// Copie profonde (énoncés + questions + choix), non publiée
  /// (`DupliquerDevoirView`, P7.2).
  Future<int> dupliquer(int devoirId) async {
    final data = await _api.post(EvaluationEndpoints.devoirsDupliquer(devoirId));
    return Map<String, dynamic>.from(data as Map)['id'] as int;
  }

  /// Publie le devoir — après quoi énoncés/questions deviennent en
  /// lecture seule (409 sur toute tentative d'ajout/modification/
  /// suppression, contrôlé côté serveur). Renvoie le message
  /// d'avertissement explicite de l'API (à afficher en confirmation
  /// APRÈS l'appel — l'écran appelant doit déjà avoir averti l'enseignant
  /// AVANT, via `YkDialog.confirm`).
  Future<String> publier(int devoirId) async {
    final data = await _api.post(EvaluationEndpoints.devoirsPublier(devoirId));
    return Map<String, dynamic>.from(data as Map)['message'] as String? ?? '';
  }

  Future<List<EnonceDevoirItem>> listerEnonces(int devoirId) async {
    final data = await _api.get(EvaluationEndpoints.devoirsEnonces(devoirId));
    final list = data as List;
    return list
        .map((e) => EnonceDevoirItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> ajouterEnonce(int devoirId, String contenu) async {
    await _api.post(EvaluationEndpoints.devoirsEnonces(devoirId), data: {'contenu': contenu});
  }

  Future<void> modifierEnonce(int enonceId, String contenu) async {
    await _api.patch(EvaluationEndpoints.devoirsEnonces2(enonceId), data: {'contenu': contenu});
  }

  Future<void> supprimerEnonce(int enonceId) async {
    await _api.delete(EvaluationEndpoints.devoirsEnonces2(enonceId));
  }

  /// Questions du devoir entier, À PLAT (`ListeQuestionsDevoirView`) —
  /// à regrouper par `enonceDevoirId` côté appelant (voir
  /// `DevoirDetailController`).
  Future<List<QuestionDevoirItem>> listerQuestions(int devoirId) async {
    final data = await _api.get(EvaluationEndpoints.devoirsQuestions(devoirId));
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((q) => QuestionDevoirItem.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  /// Ajoute une question, rattachée à UN énoncé précis
  /// (`AjouterQuestionEnonceDevoirView` — jamais l'ancien endpoint
  /// devoir-niveau, déprécié, qui ne rattachait `enonce_devoir` à rien).
  Future<void> ajouterQuestion({
    required int enonceId,
    required String enonce,
    required String typeQuestion,
    required double points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  }) async {
    await _api.post(
      EvaluationEndpoints.devoirsEnoncesQuestions(enonceId),
      data: {
        'enonce': enonce,
        'type_question': typeQuestion,
        'points': points,
        if (typeQuestion == 'qcm')
          'choix': (choix ?? const <ChoixReponseItem>[]).map((c) => c.toJson()).toList()
        else ...{
          'reponse_attendue': reponseAttendue ?? '',
          if (reponseExemple != null) 'reponse_exemple': reponseExemple,
        },
      },
    );
  }

  Future<void> modifierQuestion({
    required int questionId,
    String? enonce,
    double? points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  }) async {
    await _api.patch(
      EvaluationEndpoints.devoirsQuestionsModifier(questionId),
      data: {
        if (enonce != null) 'enonce': enonce,
        if (points != null) 'points': points,
        if (reponseAttendue != null) 'reponse_attendue': reponseAttendue,
        if (reponseExemple != null) 'reponse_exemple': reponseExemple,
        if (choix != null) 'choix': choix.map((c) => c.toJson()).toList(),
      },
    );
  }

  Future<void> supprimerQuestion(int questionId) async {
    await _api.delete(EvaluationEndpoints.devoirsQuestionsSupprimer(questionId));
  }

  Future<List<SoumissionDevoirItem>> listerSoumissions(int devoirId) async {
    final data = await _api.get(EvaluationEndpoints.devoirsSoumissions(devoirId));
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((s) => SoumissionDevoirItem.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
  }

  /// Détail d'une soumission pour la correction (réponses par question,
  /// snapshot énoncé/choix/bonne réponse — P7.3). Pas de modèle typé
  /// unique ici, cohérent avec `soumettre()` ci-dessus.
  Future<Map<String, dynamic>> detailSoumission(int soumissionId) async {
    final data = await _api.get(EvaluationEndpoints.soumissionsDetail(soumissionId));
    return Map<String, dynamic>.from(data as Map);
  }

  /// Note + mot justificatif FACULTATIF (`commentaire`, P7.3).
  Future<void> corrigerSoumission(
    int soumissionId, {
    required double note,
    String commentaire = '',
  }) async {
    await _api.patch(
      EvaluationEndpoints.soumissionsCorriger(soumissionId),
      data: {'note': note, 'commentaire': commentaire},
    );
  }
}
