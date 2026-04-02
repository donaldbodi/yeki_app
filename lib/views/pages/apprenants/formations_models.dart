// lib/views/pages/apprenants/formations_models.dart
// ════════════════════════════════════════════════════════════════
// Modèles Flutter enrichis pour Prépa Concours & Formations
// ════════════════════════════════════════════════════════════════

import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'https://yeki.pythonanywhere.com/api';

// ══════════════════════════════════════════════════════════════
// COURS ITEM
// ══════════════════════════════════════════════════════════════
class CoursItem {
  final int id;
  final String title;
  final String description;
  final String enseignantPrincipal;
  final int lessons;
  final int assignments;
  final String icon;
  final String color;
  final double progression;
  final int departementId;
  final String departementNom;
  final String parcoursNom;

  const CoursItem({
    required this.id,
    required this.title,
    required this.description,
    required this.enseignantPrincipal,
    required this.lessons,
    required this.assignments,
    required this.icon,
    required this.color,
    required this.progression,
    required this.departementId,
    required this.departementNom,
    this.parcoursNom = '',
  });

  factory CoursItem.fromJson(Map<String, dynamic> j) => CoursItem(
        id: j['id'] ?? 0,
        title: j['title'] ?? j['titre'] ?? '',
        description: j['description'] ?? '',
        enseignantPrincipal: j['enseignant_principal'] ?? '—',
        lessons: j['lessons'] ?? j['nb_lecons'] ?? 0,
        assignments: j['assignments'] ?? j['nb_devoirs'] ?? 0,
        icon: j['icon'] ?? 'school',
        color: j['color'] ?? '#2884A0',
        progression: (j['progression'] as num? ?? 0).toDouble(),
        departementId: j['departement_id'] ?? 0,
        departementNom: j['departement_nom'] ?? '',
        parcoursNom: j['parcours_nom'] ?? '',
      );
}

// ══════════════════════════════════════════════════════════════
// CADRE INFO
// ══════════════════════════════════════════════════════════════
class CadreInfo {
  final int id;
  final String nom;
  final String email;

  const CadreInfo({required this.id, required this.nom, this.email = ''});

  factory CadreInfo.fromJson(Map<String, dynamic> j) => CadreInfo(
        id: j['id'] ?? 0,
        nom: j['nom'] ?? '',
        email: j['email'] ?? '',
      );
}

// ══════════════════════════════════════════════════════════════
// TYPE DE DÉPARTEMENT
// ══════════════════════════════════════════════════════════════
enum TypeDepartement { cursus, prepa, formationMetier, formationClassique }

TypeDepartement typeDeptFromString(Map<String, dynamic> j) {
  if (j['est_prepa_concours'] == true) return TypeDepartement.prepa;
  if (j['est_formation_metier'] == true) return TypeDepartement.formationMetier;
  if (j['est_formation_classique'] == true) return TypeDepartement.formationClassique;
  final t = j['type'] as String? ?? '';
  if (t == 'prepa_concours') return TypeDepartement.prepa;
  if (t == 'formation_metier') return TypeDepartement.formationMetier;
  if (t == 'formation_classique') return TypeDepartement.formationClassique;
  return TypeDepartement.cursus;
}

// ══════════════════════════════════════════════════════════════
// DÉPARTEMENT ITEM — modèle unifié
// ══════════════════════════════════════════════════════════════
class DepartementItem {
  final int id;
  final String nom;
  final String description;
  final String? imageUrl;
  final String couleur;
  final int prix;
  final bool estActif;
  final TypeDepartement type;
  final int parcoursId;
  final String parcoursNom;
  final String parcoursType;
  final CadreInfo? cadre;
  final int nbCours;
  final double progressionMoyenne;
  final List<CoursItem> cours;
  final DateTime? createdAt;

  // Prépa Concours
  final bool estPrepaConcours;
  final String nomConcours;
  final String organismeConcours;
  final String? dateLimiteInscription;
  final String? dateExamen;
  final String arreteMinisteriel;
  final String lienOfficiel;
  final String niveauxCibles;
  final int? placesDisponibles;
  final int fraisDossier;
  final String debouches;

  // Formation
  final bool estFormationMetier;
  final bool estFormationClassique;
  final String dureeFormation;
  final String modeFormation;
  final String certificatDelivre;
  final String prerequis;
  final String objectifs;
  final String domaine;
  final String ville;
  final bool estCertifiante;

  const DepartementItem({
    required this.id,
    required this.nom,
    this.description = '',
    this.imageUrl,
    this.couleur = '#2884A0',
    this.prix = 0,
    this.estActif = true,
    required this.type,
    required this.parcoursId,
    required this.parcoursNom,
    this.parcoursType = '',
    this.cadre,
    required this.nbCours,
    required this.progressionMoyenne,
    required this.cours,
    this.createdAt,
    this.estPrepaConcours = false,
    this.nomConcours = '',
    this.organismeConcours = '',
    this.dateLimiteInscription,
    this.dateExamen,
    this.arreteMinisteriel = '',
    this.lienOfficiel = '',
    this.niveauxCibles = '',
    this.placesDisponibles,
    this.fraisDossier = 0,
    this.debouches = '',
    this.estFormationMetier = false,
    this.estFormationClassique = false,
    this.dureeFormation = '',
    this.modeFormation = '',
    this.certificatDelivre = '',
    this.prerequis = '',
    this.objectifs = '',
    this.domaine = '',
    this.ville = '',
    this.estCertifiante = false,
  });

  factory DepartementItem.fromJson(Map<String, dynamic> j) {
    final typeDept = typeDeptFromString(j);
    CadreInfo? cadre;
    if (j['cadre'] != null) {
      cadre = CadreInfo.fromJson(j['cadre'] as Map<String, dynamic>);
    }
    final coursList = (j['cours'] as List? ?? [])
        .map((c) => CoursItem.fromJson(c as Map<String, dynamic>))
        .toList();

    DateTime? createdAt;
    if (j['created_at'] != null) {
      try {
        createdAt = DateTime.parse(j['created_at']);
      } catch (_) {}
    }

    return DepartementItem(
      id: j['id'] ?? 0,
      nom: j['nom'] ?? '',
      description: j['description'] ?? '',
      imageUrl: j['image_url'] as String?,
      couleur: j['couleur'] ?? '#2884A0',
      prix: j['prix'] ?? 0,
      estActif: j['est_actif'] ?? true,
      type: typeDept,
      parcoursId: j['parcours_id'] ?? 0,
      parcoursNom: j['parcours_nom'] ?? '',
      parcoursType: j['parcours_type'] ?? '',
      cadre: cadre,
      nbCours: j['nb_cours'] ?? coursList.length,
      progressionMoyenne: (j['progression_moyenne'] as num? ?? 0).toDouble(),
      cours: coursList,
      createdAt: createdAt,
      estPrepaConcours: j['est_prepa_concours'] ?? false,
      nomConcours: j['nom_concours'] ?? '',
      organismeConcours: j['organisme_concours'] ?? '',
      dateLimiteInscription: j['date_limite_inscription'] as String?,
      dateExamen: j['date_examen'] as String?,
      arreteMinisteriel: j['arrete_ministeriel'] ?? '',
      lienOfficiel: j['lien_officiel'] ?? '',
      niveauxCibles: j['niveaux_cibles'] ?? '',
      placesDisponibles: j['places_disponibles'] as int?,
      fraisDossier: j['frais_dossier'] ?? 0,
      debouches: j['debouches'] ?? '',
      estFormationMetier: j['est_formation_metier'] ?? false,
      estFormationClassique: j['est_formation_classique'] ?? false,
      dureeFormation: j['duree_formation'] ?? '',
      modeFormation: j['mode_formation'] ?? '',
      certificatDelivre: j['certificat_delivre'] ?? '',
      prerequis: j['prerequis'] ?? '',
      objectifs: j['objectifs'] ?? '',
      domaine: j['domaine'] ?? '',
      ville: j['ville'] ?? '',
      estCertifiante: j['est_certifiante'] ?? false,
    );
  }

  double get progression => progressionMoyenne;

  String get statut {
    if (progressionMoyenne >= 100) return 'TERMINÉ';
    if (progressionMoyenne > 0) return 'EN COURS';
    return 'NOUVEAU';
  }

  bool get estGratuit => prix == 0;

  String get modeFormationLabel {
    switch (modeFormation) {
      case 'presentiel':
        return 'Présentiel';
      case 'distance':
        return 'À distance';
      default:
        return 'Hybride';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// SERVICE DE NIVEAU
// ══════════════════════════════════════════════════════════════
class NiveauService {
  static const String _key = 'niveau_apprenant';
  
  static Future<String?> getNiveau() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
  
  static Future<void> setNiveau(String niveau) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, niveau);
  }
  
  static int getOrdre(String niveau) {
    const ordre = {
      '6eme': 1, '5eme': 2, '4eme': 3, '3eme': 4,
      'seconde': 5, 'premiere': 6, 'terminale': 7,
      'licence1': 8, 'licence2': 9, 'licence3': 10,
      'master1': 11, 'master2': 12,
    };
    return ordre[niveau] ?? 0;
  }
  
  static bool estAccessible(String niveauApprenant, String niveauxCibles) {
    if (niveauApprenant.isEmpty || niveauxCibles.isEmpty) return true;
    
    final scoreApp = getOrdre(niveauApprenant);
    final cibles = niveauxCibles.toLowerCase().split(',').map((e) => e.trim()).toList();
    
    for (final cible in cibles) {
      if (getOrdre(cible) <= scoreApp) return true;
    }
    return false;
  }
}