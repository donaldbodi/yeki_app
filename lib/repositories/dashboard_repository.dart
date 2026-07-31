import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Tableaux de bord enseignants (P11.5) — migre les appels `http` bruts
/// des 4 dashboards (secondaire/principal/cadre/coordonnateur) vers
/// `ApiClient`. Les réponses restent des `Map`/`List` brutes (pas de
/// modèles typés) : chaque dashboard a un schéma trop différent des 3
/// autres pour justifier un modèle partagé dans le périmètre de ce
/// ticket (squelette + `YkStatCard`, pas une refonte de la couche
/// données) — cohérent avec l'usage déjà fait de ces mêmes champs bruts
/// dans les écrans avant migration.
class DashboardRepository {
  final ApiClient _api;

  DashboardRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> secondaire() async {
    final data = await _api.get(AccountsEndpoints.enseignantDashboard);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> principal() async {
    final data = await _api.get(FormationEndpoints.principalDashboardStats);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> principalCours() async {
    final data = await _api.get(FormationEndpoints.enseignantPrincipalCours);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> ajouterEnseignant(int coursId, int enseignantId) =>
      _api.post(FormationEndpoints.coursAddEnseignant(coursId), data: {'enseignant_id': enseignantId});

  Future<void> retirerEnseignant(int coursId, int enseignantId) =>
      _api.post(FormationEndpoints.coursRemoveEnseignant(coursId), data: {'enseignant_id': enseignantId});

  /// [role] : `'enseignant'`/`'principal'`/`'cadre'` — filtre backend.
  Future<List<Map<String, dynamic>>> enseignantsListe(String role) async {
    final data = await _api.get(AccountsEndpoints.enseignantsListe, query: {'role': role});
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> cadre() async {
    final data = await _api.get(FormationEndpoints.enseignantCadreDashboard);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> mesOlympiadesCadre() async {
    final data = await _api.get(EvaluationEndpoints.olympiadesCadreMesOlympiades);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> changerEnseignantPrincipal(int coursId, int enseignantId) => _api.patch(
    FormationEndpoints.coursChangerEnseignantPrincipal(coursId),
    data: {'enseignant_principal_id': enseignantId},
  );

  Future<List<Map<String, dynamic>>> cadreDevoirs() async {
    final data = await _api.get(EvaluationEndpoints.devoirsCadreMesDevoirs);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> lierDevoirOlympiade(int olympiadeId, int devoirId) =>
      _api.post(EvaluationEndpoints.olympiadesLierDevoir(olympiadeId), data: {'devoir_id': devoirId});

  Future<Map<String, dynamic>> admin() async {
    final data = await _api.get(AccountsEndpoints.enseignantAdminDashboard);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> tousLesCours() async {
    final data = await _api.get(FormationEndpoints.cours);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> changerCadre(int departementId, int cadreId) =>
      _api.patch(FormationEndpoints.departementsChangerCadre(departementId), data: {'cadre_id': cadreId});

  Future<void> creerDepartement(Map<String, dynamic> donnees) =>
      _api.post(FormationEndpoints.departementsCreer, data: donnees);

  Future<void> modifierDepartement(int departementId, Map<String, dynamic> donnees) =>
      _api.patch(FormationEndpoints.adminDepartementsUpdate(departementId), data: donnees);

  /// Cours d'un département, vue gestion (`nb_apprenants`/`taux_completion`
  /// par cours) — schéma distinct de `CoursRepository.listForDepartement`
  /// (vue catalogue apprenant, `CoursItem`, sans ces champs de suivi).
  Future<List<Map<String, dynamic>>> departementCours(int departementId) async {
    final data = await _api.get(FormationEndpoints.departementsCours(departementId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
