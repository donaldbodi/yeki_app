// formations_models.dart
// Modèles Dart pour formations classiques, métier et concours

const String kBaseUrl = 'https://yekiapp.pythonanywhere.com/api';

// ═══════════════════════════════════════════════════════════════
// FORMATIONS CLASSIQUES
// ═══════════════════════════════════════════════════════════════

class CoursClassique {
  final int    id;
  final String titre;
  final String matiere;
  final String niveau;
  final String enseignant;
  final int    nbLecons;
  final String duree;
  final int    ordre;

  const CoursClassique({
    required this.id,
    required this.titre,
    required this.matiere,
    required this.niveau,
    required this.enseignant,
    required this.nbLecons,
    required this.duree,
    required this.ordre,
  });

  factory CoursClassique.fromJson(Map<String, dynamic> j) => CoursClassique(
    id:          j['id'],
    titre:       j['titre'] ?? '',
    matiere:     j['matiere'] ?? '',
    niveau:      j['niveau'] ?? '',
    enseignant:  j['enseignant'] ?? '',
    nbLecons:    j['nb_lecons'] ?? 0,
    duree:       j['duree'] ?? '',
    ordre:       j['ordre'] ?? 0,
  );
}

class FormationClassique {
  final int          id;
  final String       ecole;
  final String       parcours;
  final String       ville;
  final String       pays;
  final String       imageUrl;
  final String       description;
  final String       type;
  final bool         estPublique;
  final int          nbCours;
  final int          nbEtudiants;
  final List<String> niveaux;
  final List<String> matieres;
  final List<CoursClassique> cours;

  const FormationClassique({
    required this.id,
    required this.ecole,
    required this.parcours,
    required this.ville,
    required this.pays,
    required this.imageUrl,
    required this.description,
    required this.type,
    required this.estPublique,
    required this.nbCours,
    required this.nbEtudiants,
    required this.niveaux,
    required this.matieres,
    this.cours = const [],
  });

  factory FormationClassique.fromJson(Map<String, dynamic> j) =>
      FormationClassique(
    id:          j['id'],
    ecole:       j['ecole'] ?? '',
    parcours:    j['parcours'] ?? '',
    ville:       j['ville'] ?? '',
    pays:        j['pays'] ?? 'Cameroun',
    imageUrl:    j['image_url'] ?? '',
    description: j['description'] ?? '',
    type:        j['type'] ?? 'grande_ecole',
    estPublique: j['est_publique'] ?? true,
    nbCours:     j['nb_cours'] ?? 0,
    nbEtudiants: j['nb_etudiants'] ?? 0,
    niveaux:     List<String>.from(j['niveaux'] ?? []),
    matieres:    List<String>.from(j['matieres'] ?? []),
    cours:       (j['cours'] as List? ?? [])
                     .map((c) => CoursClassique.fromJson(c))
                     .toList(),
  );
}


// ═══════════════════════════════════════════════════════════════
// FORMATIONS MÉTIER
// ═══════════════════════════════════════════════════════════════

class ModuleMetier {
  final int    id;
  final String titre;
  final String duree;
  final String statut; // fait | en_cours | non_commence
  final bool   locked;
  final int    ordre;

  const ModuleMetier({
    required this.id,
    required this.titre,
    required this.duree,
    required this.statut,
    required this.locked,
    required this.ordre,
  });

  factory ModuleMetier.fromJson(Map<String, dynamic> j) => ModuleMetier(
    id:     j['id'],
    titre:  j['titre'] ?? '',
    duree:  j['duree'] ?? '',
    statut: j['statut'] ?? 'non_commence',
    locked: j['locked'] ?? false,
    ordre:  j['ordre'] ?? 0,
  );
}

class EntreeClassement {
  final int    rang;
  final String nom;
  final String username;
  final int    score;

  const EntreeClassement({
    required this.rang,
    required this.nom,
    required this.username,
    required this.score,
  });

  factory EntreeClassement.fromJson(Map j) => EntreeClassement(
    rang:     j['rang'],
    nom:      j['nom'] ?? '',
    username: j['username'] ?? '',
    score:    j['score'] ?? 0,
  );
}

class FormationMetier {
  final int          id;
  final String       nom;
  final String       description;
  final String       objectif;
  final String       imageUrl;
  final double       prix;
  final String       domaine;
  final String       niveau;
  final int          dureeJours;
  final bool         incubateur;
  final double       noteMoyenne;
  final int          nbInscrits;
  final int          nbCours;
  final List<String> competences;
  final List<Map<String, String>> fondateurs;
  final bool         estInscrit;
  final int?         monRang;
  final List<ModuleMetier>       cours;
  final List<EntreeClassement>   classement;

  const FormationMetier({
    required this.id,
    required this.nom,
    required this.description,
    required this.objectif,
    required this.imageUrl,
    required this.prix,
    required this.domaine,
    required this.niveau,
    required this.dureeJours,
    required this.incubateur,
    required this.noteMoyenne,
    required this.nbInscrits,
    required this.nbCours,
    required this.competences,
    required this.fondateurs,
    required this.estInscrit,
    this.monRang,
    this.cours = const [],
    this.classement = const [],
  });

  factory FormationMetier.fromJson(Map<String, dynamic> j) => FormationMetier(
    id:          j['id'],
    nom:         j['nom'] ?? '',
    description: j['description'] ?? '',
    objectif:    j['objectif'] ?? '',
    imageUrl:    j['image_url'] ?? '',
    prix:        (j['prix'] as num?)?.toDouble() ?? 0,
    domaine:     j['domaine'] ?? 'Tech',
    niveau:      j['niveau'] ?? 'debutant',
    dureeJours:  j['duree_jours'] ?? 30,
    incubateur:  j['incubateur'] ?? false,
    noteMoyenne: (j['note_moyenne'] as num?)?.toDouble() ?? 0,
    nbInscrits:  j['nb_inscrits'] ?? 0,
    nbCours:     j['nb_cours'] ?? 0,
    competences: List<String>.from(j['competences'] ?? []),
    fondateurs:  (j['fondateurs'] as List? ?? [])
                     .map((f) => Map<String, String>.from(f))
                     .toList(),
    estInscrit:  j['est_inscrit'] ?? false,
    monRang:     j['mon_rang'] as int?,
    cours:       (j['cours'] as List? ?? [])
                     .map((m) => ModuleMetier.fromJson(m))
                     .toList(),
    classement:  (j['classement'] as List? ?? [])
                     .map((e) => EntreeClassement.fromJson(e))
                     .toList(),
  );
}


// ═══════════════════════════════════════════════════════════════
// CONCOURS
// ═══════════════════════════════════════════════════════════════

class ModuleConcours {
  final int    id;
  final String titre;
  final String description;

  const ModuleConcours({
    required this.id,
    required this.titre,
    required this.description,
  });

  factory ModuleConcours.fromJson(Map j) => ModuleConcours(
    id:          j['id'],
    titre:       j['titre'] ?? '',
    description: j['description'] ?? '',
  );
}

class Concours {
  final int    id;
  final String titre;
  final String description;
  final String imageUrl;
  final double prix;
  final String niveau;
  final String dateLimite;
  final int    nbInscrits;
  final int    tauxReussite;
  final int    joursRestants;
  final int    nbModules;
  final bool   estSouscrit;
  final List<ModuleConcours> modules;

  const Concours({
    required this.id,
    required this.titre,
    required this.description,
    required this.imageUrl,
    required this.prix,
    required this.niveau,
    required this.dateLimite,
    required this.nbInscrits,
    required this.tauxReussite,
    required this.joursRestants,
    required this.nbModules,
    required this.estSouscrit,
    this.modules = const [],
  });

  factory Concours.fromJson(Map<String, dynamic> j) => Concours(
    id:           j['id'],
    titre:        j['titre'] ?? '',
    description:  j['description'] ?? '',
    imageUrl:     j['image_url'] ?? '',
    prix:         (j['prix'] as num?)?.toDouble() ?? 0,
    niveau:       j['niveau'] ?? '',
    dateLimite:   j['date_limite'] ?? '',
    nbInscrits:   j['nb_inscrits'] ?? 0,
    tauxReussite: j['taux_reussite'] ?? 0,
    joursRestants: j['jours_restants'] ?? 0,
    nbModules:    j['nb_modules'] ?? 0,
    estSouscrit:  j['est_souscrit'] ?? false,
    modules:      (j['modules'] as List? ?? [])
                      .map((m) => ModuleConcours.fromJson(m))
                      .toList(),
  );
}
