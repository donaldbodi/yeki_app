import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show DepartementItem;

/// Un parcours (Cursus, Prépa Concours, Formations, etc.) — uniquement les
/// champs utiles à un menu déroulant, pas le modèle complet (voir
/// `ParcoursSerializer` côté backend, beaucoup plus riche).
class ParcoursOption {
  const ParcoursOption({required this.id, required this.nom, required this.typeParcours});

  final int id;
  final String nom;
  final String typeParcours;

  factory ParcoursOption.fromJson(Map<String, dynamic> json) => ParcoursOption(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        typeParcours: json['type_parcours'] as String? ?? '',
      );
}

/// Un département — uniquement les champs utiles à un menu déroulant, pas
/// le modèle complet (voir `DepartementSerializer` côté backend).
class DepartementOption {
  const DepartementOption({required this.id, required this.nom, required this.parcoursId});

  final int id;
  final String nom;
  final int? parcoursId;

  factory DepartementOption.fromJson(Map<String, dynamic> json) => DepartementOption(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        parcoursId: json['parcours'] as int?,
      );
}

/// Parcours/départements/niveaux — CDC_DESIGN P5.4. Fonction canonique
/// unique consommée par tous les écrans qui ont besoin de ces listes
/// (inscription, filtres devoirs, création d'olympiade, tableau de bord
/// admin) — remplace 4 implémentations ad hoc qui dupliquaient chacune
/// leur propre appel réseau (voir docs/ecarts/register.md).
class FormationRepository {
  final ApiClient _api;

  FormationRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  List<T> _asList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ParcoursOption>> parcours() async {
    final data = await _api.get(FormationEndpoints.parcours);
    return _asList(data, ParcoursOption.fromJson);
  }

  Future<List<DepartementOption>> departementsForParcours(int parcoursId) async {
    final data = await _api.get(FormationEndpoints.parcoursDepartements(parcoursId));
    return _asList(data, DepartementOption.fromJson);
  }

  /// Niveaux distincts d'un département — endpoint public (consulté avant
  /// connexion depuis l'inscription).
  Future<List<String>> niveauxForDepartement(int departementId) async {
    final data = await _api.get(FormationEndpoints.departementsNiveaux(departementId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => e.toString()).toList();
  }

  /// Niveaux distincts, toutes plateformes confondues — pour les écrans
  /// authentifiés qui filtrent sans se limiter à un département (filtre
  /// devoirs, création d'olympiade, tableau de bord admin).
  Future<List<String>> niveaux() async {
    final data = await _api.get(FormationEndpoints.niveaux);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => e.toString()).toList();
  }

  /// Détail complet d'un département (concours/formation), vue apprenant
  /// — P8.3 : `concours_detail_page.dart` appelait à la main
  /// `${baseUrl}/departement/${id}/` (chemin inexistant côté backend,
  /// sans le préfixe `apprenant/` — confirmé en comparant avec
  /// `formation_detail_page.dart`, qui utilise déjà la bonne route).
  /// Corrigé ici via `FormationEndpoints.apprenantDepartement`
  /// (`ApprenantDepartementDetailView`, `GET /apprenant/departement/<pk>/`).
  Future<DepartementItem> detailApprenant(int departementId) async {
    final data = await _api.get(FormationEndpoints.apprenantDepartement(departementId));
    return DepartementItem.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
