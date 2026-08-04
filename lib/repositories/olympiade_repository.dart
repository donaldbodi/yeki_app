import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/olympiade_models.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart'
    show OlympiadeItem;

/// Olympiades. `demarrer`/`soumettre`/`focus-perdu` (composition) restent
/// hors périmètre : depuis P7.1, la composition d'une olympiade passe par
/// le `Devoir` lié (`ComposerDevoirPage`, P7.5), pas par un flux dédié.
/// `creer`/`modifier` (authoring cadre) migrés en P8.2. `pourMoi`/
/// `getDetailApprenant`/`inscrire`/`payerParticipation`/`classement`
/// migrés en P8.3 — remplacent les appels `http` bruts de
/// `olympiades_page.dart`/`olympiade_inscription_page.dart`/
/// `classement_olympiade.dart`/`sheet_inscription.dart` (supprimé).
class OlympiadeRepository {
  final ApiClient _api;

  OlympiadeRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<OlympiadeItem>> list() async {
    final data = await _api.get(EvaluationEndpoints.olympiades);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => OlympiadeItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OlympiadeItem> getDetail(int id) async {
    final data = await _api.get(EvaluationEndpoints.olympiadesDetail(id));
    return OlympiadeItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Olympiades accessibles à l'apprenant connecté — DIFFÉRENT de
  /// `list()` (`/olympiades/`, non filtré niveau/cursus côté apprenant à
  /// l'origine, corrigé en P8.1) : `/olympiades/pour-moi/` filtre déjà
  /// par niveau côté serveur nativement (`OlympiadesPourMoiView`).
  Future<List<OlympiadeApprenant>> pourMoi() async {
    final data = await _api.get(EvaluationEndpoints.olympiadesPourMoi);
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((o) => OlympiadeApprenant.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();
  }

  Future<OlympiadeApprenant> getDetailApprenant(int id) async {
    final data = await _api.get(EvaluationEndpoints.olympiadesDetail(id));
    return OlympiadeApprenant.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Inscription — l'acceptation du règlement est déjà systématique côté
  /// serveur pour cet appel (aucun champ optionnel côté client).
  /// `ApiException` avec `PaymentRequiredError` (402) si l'olympiade est
  /// payante et pas encore réglée — à l'appelant de proposer
  /// `YkManualPaymentFlow` puis de réessayer.
  Future<void> inscrire(int olympiadeId) async {
    await _api.post(EvaluationEndpoints.olympiadesInscrire(olympiadeId), data: {'accepte_reglement': true});
  }

  Future<void> payerParticipation(int olympiadeId, int montant) async {
    await _api.post(
      EvaluationEndpoints.olympiadesPayerParticipation(olympiadeId),
      data: {'montant': montant},
    );
  }

  /// Classement — paginé (`PaginatedListMixin` côté backend) ; l'ancien
  /// `classement_olympiade.dart` faisait `jsonDecode(...) as List`, un
  /// cast direct qui aurait échoué dès que la réponse n'est pas un
  /// tableau brut (corrigé ici).
  Future<List<ClassementOlympiadeEntry>> classement(int olympiadeId) async {
    final data = await _api.get(EvaluationEndpoints.olympiadesClassement(olympiadeId));
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((e) => ClassementOlympiadeEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Map<String, dynamic> _payload({
    required String titre,
    required String description,
    required String edition,
    required String recompense,
    required int prixParticipation,
    required bool demandePaiementParticipants,
    required List<String> niveauxAccessibles,
    required DateTime dateOuvertureInscription,
    required DateTime dateClotureInscription,
    required DateTime dateDebutOlympiade,
    required int dureeMinutes,
    required int nbQuestions,
    required int maxFocusPerdu,
    required bool melangerQuestions,
    required bool melangerChoix,
    required bool uneSeuleSession,
  }) => {
    'titre': titre,
    'description': description,
    'edition': edition,
    'recompense': recompense,
    'prix_participation': prixParticipation,
    'demande_paiement_participants': demandePaiementParticipants,
    'niveaux_accessibles': niveauxAccessibles,
    'date_ouverture_inscription': dateOuvertureInscription.toIso8601String(),
    'date_cloture_inscription': dateClotureInscription.toIso8601String(),
    'date_debut_olympiade': dateDebutOlympiade.toIso8601String(),
    // date_fin_olympiade n'est JAMAIS envoyée : calculée côté serveur
    // (date_debut_olympiade + duree_minutes) — P8.1.
    'duree_minutes': dureeMinutes,
    'nb_questions': nbQuestions,
    'max_focus_perdu': maxFocusPerdu,
    'melanger_questions': melangerQuestions,
    'melanger_choix': melangerChoix,
    'une_seule_session': uneSeuleSession,
  };

  /// Création — gratuite, publication immédiate (P8.1). Renvoie l'id créé.
  Future<int> creer({
    required int departementId,
    required String titre,
    String description = '',
    String edition = '',
    String recompense = '',
    required int prixParticipation,
    required bool demandePaiementParticipants,
    List<String> niveauxAccessibles = const [],
    required DateTime dateOuvertureInscription,
    required DateTime dateClotureInscription,
    required DateTime dateDebutOlympiade,
    required int dureeMinutes,
    required int nbQuestions,
    required int maxFocusPerdu,
    required bool melangerQuestions,
    required bool melangerChoix,
    required bool uneSeuleSession,
  }) async {
    final data = await _api.post(
      EvaluationEndpoints.olympiadesCadreCreer,
      data: {
        'departement_id': departementId,
        ..._payload(
          titre: titre,
          description: description,
          edition: edition,
          recompense: recompense,
          prixParticipation: prixParticipation,
          demandePaiementParticipants: demandePaiementParticipants,
          niveauxAccessibles: niveauxAccessibles,
          dateOuvertureInscription: dateOuvertureInscription,
          dateClotureInscription: dateClotureInscription,
          dateDebutOlympiade: dateDebutOlympiade,
          dureeMinutes: dureeMinutes,
          nbQuestions: nbQuestions,
          maxFocusPerdu: maxFocusPerdu,
          melangerQuestions: melangerQuestions,
          melangerChoix: melangerChoix,
          uneSeuleSession: uneSeuleSession,
        ),
      },
    );
    return Map<String, dynamic>.from(data as Map)['id'] as int;
  }

  /// Modification — n'est permise par le serveur que tant que l'olympiade
  /// n'a pas de devoir lié ni n'est validée (`CadreModifierOlympiadeView`).
  /// Envoie l'état complet du formulaire plutôt qu'un diff : le serveur
  /// n'applique que les clés présentes, envoyer l'état courant en entier
  /// reste correct et plus simple.
  Future<void> modifier(
    int olympiadeId, {
    required String titre,
    String description = '',
    String edition = '',
    String recompense = '',
    required int prixParticipation,
    required bool demandePaiementParticipants,
    List<String> niveauxAccessibles = const [],
    required DateTime dateOuvertureInscription,
    required DateTime dateClotureInscription,
    required DateTime dateDebutOlympiade,
    required int dureeMinutes,
    required int nbQuestions,
    required int maxFocusPerdu,
    required bool melangerQuestions,
    required bool melangerChoix,
    required bool uneSeuleSession,
  }) async {
    await _api.patch(
      EvaluationEndpoints.olympiadesModifier(olympiadeId),
      data: _payload(
        titre: titre,
        description: description,
        edition: edition,
        recompense: recompense,
        prixParticipation: prixParticipation,
        demandePaiementParticipants: demandePaiementParticipants,
        niveauxAccessibles: niveauxAccessibles,
        dateOuvertureInscription: dateOuvertureInscription,
        dateClotureInscription: dateClotureInscription,
        dateDebutOlympiade: dateDebutOlympiade,
        dureeMinutes: dureeMinutes,
        nbQuestions: nbQuestions,
        maxFocusPerdu: maxFocusPerdu,
        melangerQuestions: melangerQuestions,
        melangerChoix: melangerChoix,
        uneSeuleSession: uneSeuleSession,
      ),
    );
  }
}
