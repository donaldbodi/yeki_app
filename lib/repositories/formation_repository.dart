import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show CoursItem, DepartementItem;
import 'package:yeki/views/pages/enseignants/departement_models.dart' show DepartementCadreDetail;

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

/// Une reprise de lecture récente (`GET /apprenant/lectures-recentes/`) —
/// carte "Continuer la lecture" (Accueil, Cursus).
class LectureRecente {
  const LectureRecente({
    required this.coursId,
    required this.coursTitre,
    required this.leconTitre,
    required this.coursColorHex,
    required this.pourcentage,
  });

  final int? coursId;
  final String coursTitre;
  final String leconTitre;
  final String? coursColorHex;
  final int pourcentage;

  factory LectureRecente.fromJson(Map<String, dynamic> json) => LectureRecente(
    coursId: json['cours_id'] as int?,
    coursTitre: json['cours_titre']?.toString() ?? '',
    leconTitre: json['lecon_titre']?.toString() ?? '',
    coursColorHex: json['cours_color'] as String?,
    pourcentage: (json['pourcentage'] as num? ?? 0).toInt(),
  );
}

/// Un niveau de formation professionnelle (`GET /niveaux-formation/`) —
/// liste fermée mais administrable, jamais figée en dur côté Flutter
/// (P11.6).
class NiveauFormation {
  const NiveauFormation({required this.code, required this.label});

  final String code;
  final String label;

  factory NiveauFormation.fromJson(Map<String, dynamic> json) =>
      NiveauFormation(code: json['code']?.toString() ?? '', label: json['label']?.toString() ?? '');
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

  /// Catalogue "Cursus" de l'apprenant connecté (`cursus_page.dart`, P11.2)
  /// — migre l'appel `http` brut vers `FormationEndpoints.apprenantCursus`
  /// (même endpoint qu'`ApiConstants.cursus`, deux systèmes de constantes
  /// pour la même route).
  Future<List<CoursItem>> cursus() async {
    final data = await _api.get(FormationEndpoints.apprenantCursus);
    return _asList(data, CoursItem.fromJson);
  }

  /// Catalogue "Prépa Concours" de l'apprenant connecté
  /// (`concours_pages.dart`, P11.2) — migre l'appel `http` brut.
  Future<List<DepartementItem>> prepaConcours() async {
    final data = await _api.get(FormationEndpoints.apprenantPrepaConcours);
    return _asList(data, DepartementItem.fromJson);
  }

  /// Catalogue "Formations" de l'apprenant connecté
  /// (`formations_pages.dart`, P11.2) — migre l'appel `http` brut.
  Future<List<DepartementItem>> formations() async {
    final data = await _api.get(FormationEndpoints.apprenantFormations);
    return _asList(data, DepartementItem.fromJson);
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

  /// Niveaux de formation professionnelle (départements "formation métier")
  /// — liste fermée mais administrable côté backend (`ParametreSysteme`),
  /// jamais figée en dur côté Flutter (P11.6).
  Future<List<NiveauFormation>> niveauxFormation() async {
    final data = await _api.get(FormationEndpoints.niveauxFormation);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => NiveauFormation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Vérifie l'accès de l'apprenant connecté à un département à accès
  /// restreint — `{acces: bool, statut: String?}` (`en_attente`/`refusee`
  /// si une demande existe déjà, absent sinon).
  Future<Map<String, dynamic>> verifierAcces(int departementId) async {
    final data = await _api.get(FormationEndpoints.apprenantDepartementAcces(departementId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> demanderAcces(int departementId, String message) async {
    await _api.post(FormationEndpoints.departementsDemanderAcces(departementId), data: {'message': message});
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

  /// Demandes d'accès à un département restreint, filtrées par statut
  /// (`en_attente`/`acceptee`/`refusee`) — `gestion_demandes_page.dart`,
  /// P11.8.
  Future<List<Map<String, dynamic>>> demandesAcces(int departementId, String statut) async {
    final data = await _api.get(FormationEndpoints.departementsDemandes(departementId), query: {'statut': statut});
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> traiterDemandeAcces(int departementId, int demandeId, {required String action, required String reponse}) =>
      _api.post(
        FormationEndpoints.departementsDemandesTraiter(departementId, demandeId),
        data: {'action': action, 'reponse': reponse},
      );

  /// Reprises de lecture récentes — carte "Continuer la lecture"
  /// (Accueil, P11.1 ; consommait déjà `cursus_page.dart` en `http` brut).
  Future<List<LectureRecente>> lecturesRecentes({int limit = 5}) async {
    final data = await _api.get(
      FormationEndpoints.apprenantLecturesRecentes,
      query: {'limit': limit.toString()},
    );
    return _asList(data, LectureRecente.fromJson);
  }

  /// Détail d'un département vu par son enseignant cadre (gestion — pas le
  /// même schéma que [detailApprenant]) — `detail_departement_page.dart`,
  /// P11.3, migre l'appel `http` brut vers `FormationEndpoints.
  /// enseignantCadreDepartement`.
  Future<DepartementCadreDetail> detailEnseignantCadre(int departementId) async {
    final data = await _api.get(FormationEndpoints.enseignantCadreDepartement(departementId));
    return DepartementCadreDetail.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
