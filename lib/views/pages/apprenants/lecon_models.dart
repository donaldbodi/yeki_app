// lib/views/pages/apprenants/lecon_models.dart
//
// Modèles Dart partagés entre les écrans leçons (P11.4) —
// `lecons_cours.dart`, `detail_lecon_page.dart`, `lecture_lecon_page.dart`.
// Consolide 2 déclarations dupliquées de `Lecon` (une par ancien fichier,
// schémas légèrement différents) en un seul modèle riche.

class LeconItem {
  const LeconItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.duree,
    required this.moduleId,
    required this.moduleTitre,
    required this.ordre,
    required this.numero,
    required this.hasPdf,
    required this.pdfUrl,
    required this.hasVideo,
    required this.videoUrl,
    required this.videoVerrouille,
    required this.estTerminee,
  });

  final int id;
  final String titre;
  final String description;

  /// Déjà formatée par le backend (ex. « 12 min ») — jamais recalculée ici.
  final String duree;
  final int moduleId;
  final String moduleTitre;
  final int ordre;

  /// Position globale toutes leçons du cours confondues (1-based) —
  /// calculée par [ModulesCours.tousLesLecons], pas par le backend.
  final int numero;
  final bool hasPdf;
  final String? pdfUrl;
  final bool hasVideo;
  final String? videoUrl;

  /// `true` si la leçon a réellement une vidéo mais qu'elle est cachée par
  /// le palier gratuit (`video_verrouille`, backend) — distinct de
  /// `!hasVideo` qui peut aussi signifier « pas de vidéo du tout ».
  final bool videoVerrouille;
  final bool estTerminee;

  factory LeconItem.fromJson(Map<String, dynamic> json, {required int moduleId, required String moduleTitre}) {
    final pdf = json['fichier_pdf']?.toString();
    final video = json['video']?.toString();
    return LeconItem(
      id: json['id'] as int,
      titre: json['titre']?.toString() ?? 'Sans titre',
      description: json['description']?.toString() ?? '',
      duree: json['duree']?.toString() ?? '',
      moduleId: moduleId,
      moduleTitre: moduleTitre,
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      numero: 0,
      hasPdf: pdf != null && pdf.isNotEmpty,
      pdfUrl: pdf,
      hasVideo: video != null && video.isNotEmpty,
      videoUrl: video,
      videoVerrouille: json['video_verrouille'] as bool? ?? false,
      estTerminee: json['est_terminee'] as bool? ?? false,
    );
  }

  LeconItem copyWith({int? numero, bool? estTerminee}) => LeconItem(
    id: id,
    titre: titre,
    description: description,
    duree: duree,
    moduleId: moduleId,
    moduleTitre: moduleTitre,
    ordre: ordre,
    numero: numero ?? this.numero,
    hasPdf: hasPdf,
    pdfUrl: pdfUrl,
    hasVideo: hasVideo,
    videoUrl: videoUrl,
    videoVerrouille: videoVerrouille,
    estTerminee: estTerminee ?? this.estTerminee,
  );
}

class ModuleAvecLecons {
  const ModuleAvecLecons({
    required this.id,
    required this.titre,
    required this.description,
    required this.ordre,
    required this.lecons,
  });

  final int id;
  final String titre;
  final String description;
  final int ordre;
  final List<LeconItem> lecons;

  factory ModuleAvecLecons.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final titre = json['titre']?.toString() ?? '';
    final leconsJson = json['lecons'] as List? ?? [];
    return ModuleAvecLecons(
      id: id,
      titre: titre,
      description: json['description']?.toString() ?? '',
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      lecons: leconsJson
          .map((e) => LeconItem.fromJson(Map<String, dynamic>.from(e as Map), moduleId: id, moduleTitre: titre))
          .toList(),
    );
  }
}

/// Un supplément de cours (P11.9) — rattaché au cours (obligatoire) + à
/// une leçon (facultative, `leconId == null` = visible sur tout le cours).
class SupplementCoursItem {
  const SupplementCoursItem({
    required this.id,
    required this.coursId,
    required this.leconId,
    required this.titre,
    required this.description,
    required this.typeContenu,
    required this.fichierUrl,
    required this.url,
    required this.ordre,
  });

  final int id;
  final int coursId;
  final int? leconId;
  final String titre;
  final String description;

  /// `'lien'` | `'pdf'` | `'ppt'` | `'autre'`.
  final String typeContenu;
  final String? fichierUrl;
  final String? url;
  final int ordre;

  /// Lien à ouvrir — le fichier téléversé s'il existe, sinon l'URL saisie.
  String? get lienAOuvrir => (fichierUrl?.isNotEmpty ?? false) ? fichierUrl : url;

  factory SupplementCoursItem.fromJson(Map<String, dynamic> json) => SupplementCoursItem(
    id: json['id'] as int,
    coursId: json['cours'] as int,
    leconId: json['lecon'] as int?,
    titre: json['titre']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    typeContenu: json['type_contenu']?.toString() ?? 'autre',
    fichierUrl: json['fichier'] as String?,
    url: json['url'] as String?,
    ordre: (json['ordre'] as num?)?.toInt() ?? 1,
  );
}

/// Métadonnées du cours (niveau, enseignant principal) — `GET
/// /cours/{id}/update/` (`CoursUpdateView`, déjà en production,
/// accessible à tout utilisateur authentifié en lecture). Utilisé pour
/// compléter l'en-tête de `cours_detail_page.dart` et la carte
/// enseignant de `lecons_cours.dart` (Phase 2, refonte identique
/// maquette).
class CoursDetailInfo {
  const CoursDetailInfo({required this.niveau, required this.enseignantNom});

  final String niveau;

  /// `"{prénom} {nom}"` — `null` si aucun enseignant principal assigné.
  /// Pas de civilité (« M. »/« Mme ») : aucune donnée de genre disponible
  /// sur `User`/`Profile`, non fabriquée.
  final String? enseignantNom;

  factory CoursDetailInfo.fromJson(Map<String, dynamic> json) {
    final principal = json['enseignant_principal'] as Map?;
    final user = principal?['user'] as Map?;
    final prenom = user?['first_name']?.toString().trim() ?? '';
    final nom = user?['last_name']?.toString().trim() ?? '';
    final nomComplet = '$prenom $nom'.trim();
    return CoursDetailInfo(
      niveau: json['niveau']?.toString() ?? '',
      enseignantNom: nomComplet.isEmpty ? null : nomComplet,
    );
  }
}

/// Vue à plat, numérotée, de toutes les leçons d'un cours — pratique pour
/// `YkLessonFeed` (une page = une leçon) et pour la navigation
/// précédent/suivant.
extension ModulesCoursX on List<ModuleAvecLecons> {
  List<LeconItem> tousLesLecons() {
    var num = 1;
    final resultat = <LeconItem>[];
    for (final module in this) {
      for (final lecon in module.lecons) {
        resultat.add(lecon.copyWith(numero: num));
        num++;
      }
    }
    return resultat;
  }
}
