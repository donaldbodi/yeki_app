// lib/features/admin_general/data/admin_general_repository.dart
//
// Administration générale (P9.6) — dashboard, gestion parcours/enseignants,
// liste des cours, transactions et tableau de bord financier. Remplace les
// appels `http` bruts + `SharedPreferences` de l'ancien
// `views/pages/enseignants/admin_general_page.dart` (refonte complète).

import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

import 'admin_general_models.dart';

class AdminGeneralRepository {
  final ApiClient _api;

  AdminGeneralRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<AdminGeneralDashboard> dashboard() async {
    final data = await _api.get(AccountsEndpoints.adminGeneralDashboard);
    return AdminGeneralDashboard.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<EnseignantAdmin>> rechercherEnseignants({
    String? q,
    String? userType,
    bool? isActive,
    int? parcoursId,
    int? departementId,
    int? coursId,
  }) async {
    final query = <String, String>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (userType != null && userType.isNotEmpty) 'user_type': userType,
      if (isActive != null) 'is_active': isActive.toString(),
      if (parcoursId != null) 'parcours_id': parcoursId.toString(),
      if (departementId != null) 'departement_id': departementId.toString(),
      if (coursId != null) 'cours_id': coursId.toString(),
    };
    final data = await _api.get(
      AccountsEndpoints.adminGeneralEnseignantsSearch,
      query: query.isEmpty ? null : query,
    );
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results.map((e) => EnseignantAdmin.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> modifierEnseignant(int profileId, {required String userType, required bool isActive}) async {
    await _api.patch(
      AccountsEndpoints.adminGeneralEnseignantsModifier(profileId),
      data: {'user_type': userType, 'is_active': isActive},
    );
  }

  Future<void> creerParcours({required String nom, required String description, required String typeParcours}) async {
    await _api.post(
      FormationEndpoints.parcoursCreer,
      data: {'nom': nom, 'description': description, 'type_parcours': typeParcours},
    );
  }

  Future<void> modifierParcours(
    int parcoursId, {
    required String nom,
    required String description,
    required String typeParcours,
  }) async {
    await _api.patch(
      FormationEndpoints.parcoursModifier(parcoursId),
      data: {'nom': nom, 'description': description, 'type_parcours': typeParcours},
    );
  }

  Future<void> nommerAdminParcours(int parcoursId, int enseignantAdminId) async {
    await _api.patch(
      FormationEndpoints.parcoursNommerAdmin(parcoursId),
      data: {'enseignant_admin_id': enseignantAdminId},
    );
  }

  /// Enseignants `enseignant_admin` actifs — pour le sélecteur « nommer/
  /// changer l'administrateur » d'un parcours.
  Future<List<AdminEnseignantRef>> enseignantsAdmins() async {
    final data = await _api.get(AccountsEndpoints.enseignantsListe, query: {'role': 'admin'});
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results.map((e) => AdminEnseignantRef.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<CoursAdmin>> tousLesCours() async {
    final data = await _api.get(FormationEndpoints.cours);
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results.map((e) => CoursAdmin.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<AdminTransaction>> transactions({
    int? departementId,
    String? categorie,
    String? du,
    String? au,
    String? statut,
  }) async {
    final query = <String, String>{
      if (departementId != null) 'departement': departementId.toString(),
      if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
      if (du != null && du.isNotEmpty) 'du': du,
      if (au != null && au.isNotEmpty) 'au': au,
      if (statut != null && statut.isNotEmpty) 'statut': statut,
    };
    final data = await _api.get(PaiementEndpoints.adminTransactions, query: query.isEmpty ? null : query);
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results.map((e) => AdminTransaction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<AdminDashboardFinancier> dashboardFinancier() async {
    final data = await _api.get(PaiementEndpoints.adminDashboardFinancier);
    return AdminDashboardFinancier.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
