// lib/views/pages/apprenants/formations_models.dart (corrigé)

const String kBaseUrl = 'https://yeki.pythonanywhere.com/api';

// Modèle de cours pour les formations
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
  final String niveau;
  
  CoursItem({
    required this.id,
    required this.title,
    required this.description,
    required this.enseignantPrincipal,
    required this.lessons,
    required this.assignments,
    required this.icon,
    required this.color,
    required this.progression,
    required this.niveau,
  });
  
  factory CoursItem.fromJson(Map<String, dynamic> json) {
    return CoursItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['titre'] ?? '',
      description: json['description'] ?? json['description_brief'] ?? '',
      enseignantPrincipal: json['enseignant_principal'] ?? '---',
      lessons: json['lessons'] ?? json['nb_lecons'] ?? 0,
      assignments: json['assignments'] ?? json['nb_devoirs'] ?? 0,
      icon: json['icon'] ?? json['icon_name'] ?? 'school',
      color: json['color'] ?? json['color_code'] ?? '#2884A0',
      progression: (json['progression'] as num?)?.toDouble() ?? 0.0,
      niveau: json['niveau'] ?? '',
    );
  }
}

// Modèle de département/formation
class DepartementItem {
  final int id;
  final String nom;
  final String description;
  final String? imageUrl;
  final String couleur;
  final int prix;
  final int nbCours;
  final double progressionMoyenne;
  final String statut;
  final String nomConcours;
  final String organismeConcours;
  final DateTime? dateLimiteInscription;
  final DateTime? dateExamen;
  final String arreteMinisteriel;
  final String lienOfficiel;
  final String niveauxCibles;
  final int? placesDisponibles;
  final int fraisDossier;
  final String debouches;
  final bool estFormationMetier;
  final bool estFormationClassique;
  final String dureeFormation;
  final String modeFormation;
  final String modeFormationLabel;
  final String certificatDelivre;
  final String prerequis;
  final String objectifs;
  final String domaine;
  final String ville;
  final bool estCertifiante;
  final List<CoursItem> cours;
  final Map<String, dynamic>? cadre;
  final double progression;
  
  DepartementItem({
    required this.id,
    required this.nom,
    required this.description,
    this.imageUrl,
    required this.couleur,
    required this.prix,
    required this.nbCours,
    required this.progressionMoyenne,
    required this.statut,
    required this.nomConcours,
    required this.organismeConcours,
    this.dateLimiteInscription,
    this.dateExamen,
    required this.arreteMinisteriel,
    required this.lienOfficiel,
    required this.niveauxCibles,
    this.placesDisponibles,
    required this.fraisDossier,
    required this.debouches,
    required this.estFormationMetier,
    required this.estFormationClassique,
    required this.dureeFormation,
    required this.modeFormation,
    required this.modeFormationLabel,
    required this.certificatDelivre,
    required this.prerequis,
    required this.objectifs,
    required this.domaine,
    required this.ville,
    required this.estCertifiante,
    required this.cours,
    this.cadre,
    required this.progression,
  });
  
  factory DepartementItem.fromJson(Map<String, dynamic> json) {
    return DepartementItem(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      couleur: json['couleur'] ?? '#2884A0',
      prix: json['prix'] ?? 0,
      nbCours: json['nb_cours'] ?? 0,
      progressionMoyenne: (json['progression_moyenne'] as num?)?.toDouble() ?? 0.0,
      statut: json['statut'] ?? 'NOUVEAU',
      nomConcours: json['nom_concours'] ?? '',
      organismeConcours: json['organisme_concours'] ?? '',
      dateLimiteInscription: json['date_limite_inscription'] != null 
          ? DateTime.tryParse(json['date_limite_inscription']) 
          : null,
      dateExamen: json['date_examen'] != null 
          ? DateTime.tryParse(json['date_examen']) 
          : null,
      arreteMinisteriel: json['arrete_ministeriel'] ?? '',
      lienOfficiel: json['lien_officiel'] ?? '',
      niveauxCibles: json['niveaux_cibles'] ?? '',
      placesDisponibles: json['places_disponibles'],
      fraisDossier: json['frais_dossier'] ?? 0,
      debouches: json['debouches'] ?? '',
      estFormationMetier: json['est_formation_metier'] ?? false,
      estFormationClassique: json['est_formation_classique'] ?? false,
      dureeFormation: json['duree_formation'] ?? '',
      modeFormation: json['mode_formation'] ?? '',
      modeFormationLabel: _getModeFormationLabel(json['mode_formation']),
      certificatDelivre: json['certificat_delivre'] ?? '',
      prerequis: json['prerequis'] ?? '',
      objectifs: json['objectifs'] ?? '',
      domaine: json['domaine'] ?? '',
      ville: json['ville'] ?? '',
      estCertifiante: json['est_certifiante'] ?? false,
      cours: (json['cours'] as List?)?.map((c) => CoursItem.fromJson(c)).toList() ?? [],
      cadre: json['cadre'],
      progression: (json['progression'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  static String _getModeFormationLabel(String? mode) {
    switch (mode) {
      case 'presentiel': return 'Présentiel';
      case 'distance': return 'À distance';
      case 'hybride': return 'Hybride';
      default: return '';
    }
  }
}

// Modèle pour les formations classiques
class FormationClassique {
  final int id;
  final String ecole;
  final String parcours;
  final String ville;
  final String pays;
  final String? imageUrl;
  final String description;
  final String type;
  final bool estPublique;
  final int nbCours;
  final int nbEtudiants;
  final List<String> niveaux;
  final List<String> matieres;
  final List<CoursClassique> cours;
  final bool estInscrit;
  
  FormationClassique({
    required this.id,
    required this.ecole,
    required this.parcours,
    required this.ville,
    required this.pays,
    this.imageUrl,
    required this.description,
    required this.type,
    required this.estPublique,
    required this.nbCours,
    required this.nbEtudiants,
    required this.niveaux,
    required this.matieres,
    required this.cours,
    required this.estInscrit,
  });
  
  factory FormationClassique.fromJson(Map<String, dynamic> json) {
    return FormationClassique(
      id: json['id'] ?? 0,
      ecole: json['ecole'] ?? '',
      parcours: json['parcours'] ?? '',
      ville: json['ville'] ?? '',
      pays: json['pays'] ?? '',
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      type: json['type'] ?? 'universite',
      estPublique: json['est_publique'] ?? false,
      nbCours: json['nb_cours'] ?? 0,
      nbEtudiants: json['nb_etudiants'] ?? 0,
      niveaux: List<String>.from(json['niveaux'] ?? []),
      matieres: List<String>.from(json['matieres'] ?? []),
      cours: (json['cours'] as List?)?.map((c) => CoursClassique.fromJson(c)).toList() ?? [],
      estInscrit: json['est_inscrit'] ?? false,
    );
  }
}

class CoursClassique {
  final int id;
  final String titre;
  final String matiere;
  final String niveau;
  final String enseignant;
  final int nbLecons;
  final String duree;
  final int ordre;
  
  CoursClassique({
    required this.id,
    required this.titre,
    required this.matiere,
    required this.niveau,
    required this.enseignant,
    required this.nbLecons,
    required this.duree,
    required this.ordre,
  });
  
  factory CoursClassique.fromJson(Map<String, dynamic> json) {
    return CoursClassique(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      matiere: json['matiere'] ?? '',
      niveau: json['niveau'] ?? '',
      enseignant: json['enseignant'] ?? '',
      nbLecons: json['nb_lecons'] ?? 0,
      duree: json['duree'] ?? '',
      ordre: json['ordre'] ?? 0,
    );
  }
}

// Modèle pour les formations métier
class FormationMetier {
  final int id;
  final String nom;
  final String description;
  final String domaine;
  final String niveau;
  final double prix;
  final int dureeJours;
  final bool incubateur;
  final double noteMoyenne;
  final int nbInscrits;
  final int nbCours;
  final List<String> competences;
  final List<Map<String, String>> fondateurs;
  final List<ModuleMetier> cours;
  final bool estInscrit;
  final int? monRang;
  final List<EntreeClassement> classement;
  final String objectif;
  final String? imageUrl;
  
  FormationMetier({
    required this.id,
    required this.nom,
    required this.description,
    required this.domaine,
    required this.niveau,
    required this.prix,
    required this.dureeJours,
    required this.incubateur,
    required this.noteMoyenne,
    required this.nbInscrits,
    required this.nbCours,
    required this.competences,
    required this.fondateurs,
    required this.cours,
    required this.estInscrit,
    this.monRang,
    required this.classement,
    required this.objectif,
    this.imageUrl,
  });
  
  factory FormationMetier.fromJson(Map<String, dynamic> json) {
    return FormationMetier(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? json['titre'] ?? '',
      description: json['description'] ?? '',
      domaine: json['domaine'] ?? '',
      niveau: json['niveau'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      dureeJours: json['duree_jours'] ?? json['duree'] ?? 0,
      incubateur: json['incubateur'] ?? false,
      noteMoyenne: (json['note_moyenne'] as num?)?.toDouble() ?? 0.0,
      nbInscrits: json['nb_inscrits'] ?? 0,
      nbCours: json['nb_cours'] ?? 0,
      competences: List<String>.from(json['competences'] ?? []),
      fondateurs: List<Map<String, String>>.from(
        (json['fondateurs'] as List?)?.map((f) => Map<String, String>.from(f)) ?? []
      ),
      cours: (json['cours'] as List?)?.map((c) => ModuleMetier.fromJson(c)).toList() ?? [],
      estInscrit: json['est_inscrit'] ?? false,
      monRang: json['mon_rang'],
      classement: (json['classement'] as List?)?.map((c) => EntreeClassement.fromJson(c)).toList() ?? [],
      objectif: json['objectif'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}

class ModuleMetier {
  final int id;
  final String titre;
  final String description;
  final String duree;
  final int ordre;
  final String statut;
  final bool locked;
  
  ModuleMetier({
    required this.id,
    required this.titre,
    required this.description,
    required this.duree,
    required this.ordre,
    required this.statut,
    required this.locked,
  });
  
  factory ModuleMetier.fromJson(Map<String, dynamic> json) {
    return ModuleMetier(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      duree: json['duree'] ?? '',
      ordre: json['ordre'] ?? 0,
      statut: json['statut'] ?? 'non_commence',
      locked: json['locked'] ?? false,
    );
  }
}

class EntreeClassement {
  final int rang;
  final String nom;
  final double score;
  
  EntreeClassement({
    required this.rang,
    required this.nom,
    required this.score,
  });
  
  factory EntreeClassement.fromJson(Map<String, dynamic> json) {
    return EntreeClassement(
      rang: json['rang'] ?? 0,
      nom: json['nom'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Service pour gérer le niveau de l'apprenant
class NiveauService {
  static const Map<String, int> niveauxOrdre = {
    '6eme': 1,
    '5eme': 2,
    '4eme': 3,
    '3eme': 4,
    'seconde': 5,
    'premiere': 6,
    'terminale': 7,
    'licence1': 8,
    'licence2': 9,
    'licence3': 10,
    'master1': 11,
    'master2': 12,
  };
  
  static Future<String?> getNiveau() async {
    // À implémenter avec SharedPreferences
    return null;
  }
  
  static bool estAccessible(String niveauApprenant, String niveauxCibles) {
    if (niveauxCibles.isEmpty) return true;
    
    final niveauScore = niveauxOrdre[niveauApprenant] ?? 0;
    
    // Extraire les niveaux cibles
    for (final niveau in niveauxOrdre.keys) {
      if (niveauxCibles.toLowerCase().contains(niveau.toLowerCase())) {
        final cibleScore = niveauxOrdre[niveau] ?? 0;
        if (cibleScore <= niveauScore) return true;
      }
    }
    
    return false;
  }
}