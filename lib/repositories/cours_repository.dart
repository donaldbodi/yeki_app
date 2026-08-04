import 'package:dio/dio.dart' show FormData, MultipartFile;

import 'package:yeki/core/design/components/inputs/yk_file_upload.dart' show YkPickedFile;
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show CoursItem;
import 'package:yeki/views/pages/apprenants/lecon_models.dart'
    show CoursDetailInfo, ModuleAvecLecons, SupplementCoursItem;

/// Cours — modules/leçons ajoutés en P11.4 (migration de `lecons_cours.dart`,
/// `detail_lecon_page.dart`, `lecture_lecon_page.dart`, qui appelaient
/// jusqu'ici `http` en direct).
class CoursRepository {
  final ApiClient _api;

  CoursRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<CoursItem>> listForDepartement(int departementId) async {
    final data = await _api.get(FormationEndpoints.departementsCours(departementId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => CoursItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Niveau + enseignant principal — `GET coursUpdate` (déjà utilisé en
  /// PATCH ; `CoursUpdateView` sert aussi le GET, `IsAuthenticated` sans
  /// restriction de rôle).
  Future<CoursDetailInfo> detail(int coursId) async {
    final data = await _api.get(FormationEndpoints.coursUpdate(coursId));
    return CoursDetailInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ModuleAvecLecons>> modules(int coursId) async {
    final data = await _api.get(FormationEndpoints.coursListeModules(coursId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => ModuleAvecLecons.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> creerModule(int coursId, {required String titre, required String description, required int ordre}) =>
      _api.post(
        FormationEndpoints.coursModules(coursId),
        data: {'titre': titre, 'description': description, 'ordre': ordre},
      );

  Future<void> modifierModule(int moduleId, {required String titre, required String description, required int ordre}) =>
      _api.patch(
        FormationEndpoints.modulesModifier(moduleId),
        data: {'titre': titre, 'description': description, 'ordre': ordre},
      );

  Future<void> supprimerModule(int moduleId) => _api.delete(FormationEndpoints.modulesSupprimer(moduleId));

  Future<void> creerLecon(
    int coursId, {
    required String titre,
    required String description,
    required int moduleId,
    YkPickedFile? pdf,
    YkPickedFile? video,
  }) =>
      _api.post(
        FormationEndpoints.coursLecons(coursId),
        data: FormData.fromMap({
          'titre': titre,
          'description': description,
          'module': moduleId.toString(),
          if (pdf != null) 'fichier_pdf': MultipartFile.fromBytes(pdf.bytes, filename: pdf.name),
          if (video != null) 'video': MultipartFile.fromBytes(video.bytes, filename: video.name),
        }),
      );

  Future<void> modifierLecon(
    int leconId, {
    required String titre,
    required String description,
    int? nouveauModuleId,
    YkPickedFile? nouveauPdf,
    YkPickedFile? nouvelleVideo,
  }) =>
      _api.patch(
        FormationEndpoints.leconsModifier(leconId),
        data: FormData.fromMap({
          'titre': titre,
          'description': description,
          if (nouveauModuleId != null) 'module': nouveauModuleId.toString(),
          if (nouveauPdf != null) 'fichier_pdf': MultipartFile.fromBytes(nouveauPdf.bytes, filename: nouveauPdf.name),
          if (nouvelleVideo != null) 'video': MultipartFile.fromBytes(nouvelleVideo.bytes, filename: nouvelleVideo.name),
        }),
      );

  Future<void> supprimerLecon(int leconId) => _api.delete(FormationEndpoints.leconsSupprimer(leconId));

  /// Statut « aimée » de la leçon pour l'apprenant connecté.
  Future<bool> verifierLike(int leconId) async {
    final data = await _api.get(FormationEndpoints.apprenantLeconLike(leconId));
    return (data as Map)['liked'] as bool? ?? false;
  }

  /// Bascule aimée/pas-aimée — le backend fait autorité sur le nouvel état.
  Future<bool> toggleLike(int leconId) async {
    final data = await _api.post(FormationEndpoints.apprenantLeconLike(leconId));
    return (data as Map)['liked'] as bool? ?? false;
  }

  /// Marque la progression de lecture d'une leçon (10 % = ouverte,
  /// 50 %/100 % = jalons PDF, 100 % = "Terminée").
  Future<void> marquerLecon(int leconId, int pourcentage) => _api.post(
    FormationEndpoints.apprenantMarquerLecon,
    data: {'lecon_id': leconId, 'pourcentage': pourcentage},
  );

  /// Création d'un cours (P11.6, migre `creer_cours_sheet.dart`).
  Future<void> creerCours({
    required int departementId,
    required String titre,
    required String niveau,
    required String colorCode,
    required String iconName,
    String? matiere,
    String? concours,
    String? descriptionBrief,
    int? enseignantPrincipalId,
    YkPickedFile? image,
  }) => _api.post(
    FormationEndpoints.coursCreate,
    data: FormData.fromMap({
      'titre': titre,
      'niveau': niveau,
      'departement': departementId.toString(),
      'color_code': colorCode,
      'icon_name': iconName,
      if (matiere != null && matiere.isNotEmpty) 'matiere': matiere,
      if (concours != null && concours.isNotEmpty) 'concours': concours,
      if (descriptionBrief != null && descriptionBrief.isNotEmpty) 'description_brief': descriptionBrief,
      if (enseignantPrincipalId != null) 'enseignant_principal': enseignantPrincipalId.toString(),
      if (image != null) 'image': MultipartFile.fromBytes(image.bytes, filename: image.name),
    }),
  );

  /// Modification d'un cours (P11.6, migre `modifier_cours_sheet.dart`).
  Future<void> modifierCours(
    int coursId, {
    required String titre,
    required String niveau,
    required String colorCode,
    required String iconName,
    String? descriptionBrief,
  }) => _api.patch(
    FormationEndpoints.coursUpdate(coursId),
    data: {
      'titre': titre,
      'niveau': niveau,
      'description_brief': descriptionBrief ?? '',
      'color_code': colorCode,
      'icon_name': iconName,
    },
  );

  /// Suppléments visibles pour ce cours — sans [leconId], uniquement ceux
  /// de portée cours ; avec [leconId], ceux-là PLUS ceux propres à cette
  /// leçon (P11.9).
  Future<List<SupplementCoursItem>> supplements(int coursId, {int? leconId}) async {
    final data = await _api.get(
      FormationEndpoints.coursSupplements(coursId),
      query: leconId != null ? {'lecon_id': leconId.toString()} : null,
    );
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => SupplementCoursItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Réservé à l'enseignant principal du cours (403 backend sinon).
  Future<void> creerSupplement(
    int coursId, {
    required String titre,
    required String typeContenu,
    String? description,
    String? url,
    int? leconId,
    YkPickedFile? fichier,
  }) => _api.post(
    FormationEndpoints.coursSupplementsCreer(coursId),
    data: FormData.fromMap({
      'titre': titre,
      'type_contenu': typeContenu,
      if (description != null && description.isNotEmpty) 'description': description,
      if (url != null && url.isNotEmpty) 'url': url,
      if (leconId != null) 'lecon': leconId.toString(),
      if (fichier != null) 'fichier': MultipartFile.fromBytes(fichier.bytes, filename: fichier.name),
    }),
  );

  Future<void> supprimerSupplement(int supplementId) => _api.delete(FormationEndpoints.supplementsSupprimer(supplementId));
}
