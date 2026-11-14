import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/repetiteur_models.dart';

/// Répétiteurs. Tranche initiale (P5.4) : recherche apprenant seulement.
/// P9.5 : administration Service Client (bascule is_repetiteur, fiches).
class RepetiteurRepository {
  final ApiClient _api;

  RepetiteurRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> search(Map<String, dynamic> filters) async {
    final data = await _api.get(
      RepetiteursEndpoints.repetiteursSearch,
      query: filters,
    );
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Administration (Service Client, P9.5) ──────────────────────────

  Future<List<RepetiteurCandidat>> candidats({bool? isRepetiteur}) async {
    final data = await _api.get(
      RepetiteursEndpoints.repetiteursAdminCandidats,
      query: isRepetiteur != null ? {'is_repetiteur': isRepetiteur.toString()} : null,
    );
    final candidats = Map<String, dynamic>.from(data as Map)['candidats'] as List? ?? [];
    return candidats
        .map((e) => RepetiteurCandidat.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<bool> toggleIsRepetiteur(int profileId, bool valeur) async {
    final data = await _api.patch(
      RepetiteursEndpoints.repetiteursAdminToggle(profileId),
      data: {'is_repetiteur': valeur},
    );
    return Map<String, dynamic>.from(data as Map)['is_repetiteur'] as bool? ?? valeur;
  }

  Future<RepetiteurFiche> creerFiche({
    required int enseignantId,
    required int coursId,
    required String ville,
    required String telephone,
    int? tarifMensuel,
  }) async {
    final data = await _api.post(
      RepetiteursEndpoints.repetiteursAdminFiches,
      data: {
        'enseignant': enseignantId,
        'cours': coursId,
        'ville': ville,
        'telephone': telephone,
        if (tarifMensuel != null) 'tarif_mensuel': tarifMensuel,
      },
    );
    return RepetiteurFiche.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<RepetiteurFiche> editerFiche(
    int ficheId, {
    String? ville,
    String? telephone,
    bool? disponible,
    int? tarifMensuel,
  }) async {
    final data = await _api.patch(
      RepetiteursEndpoints.repetiteursAdminFichesDetail(ficheId),
      data: {
        if (ville != null) 'ville': ville,
        if (telephone != null) 'telephone': telephone,
        if (disponible != null) 'disponible': disponible,
        if (tarifMensuel != null) 'tarif_mensuel': tarifMensuel,
      },
    );
    return RepetiteurFiche.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> retirerFiche(int ficheId) async {
    await _api.delete(RepetiteursEndpoints.repetiteursAdminFichesDetail(ficheId));
  }
}
