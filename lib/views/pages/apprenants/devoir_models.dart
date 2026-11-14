// devoir_models.dart
// Modèles Dart partagés entre toutes les pages devoirs.
//
// P11.2 : `DevoirModel`/`OlympiadeInfo` retirés — code mort confirmé
// (aucun appelant réel, `DevoirRepository.listMine()` qui les utilisait
// n'avait elle-même aucun appelant avant ce ticket). `DevoirItem`, le
// modèle RÉELLEMENT éprouvé en production par `devoirs_page.dart`
// (statut apprenant, note, cache hors-ligne), déménage ici depuis ce
// fichier pour que `DevoirRepository` puisse le consommer sans créer un
// import circulaire `devoirs_page.dart` ↔ `devoir_repository.dart`.
//
// P7.5 : `ChoixDevoir`/`QuestionDevoir`/`DevoirDetail` (vue composition
// apprenant) supprimés — 0 appelant restant (confirmé par recherche),
// remplacés par `ChoixDevoirComposer`/`QuestionDevoirComposer`/
// `DevoirAComposer` (`lib/models/devoir_models.dart`), qui corrigent au
// passage un bug réel : `QuestionDevoir.fromJson` lisait `j['texte']` pour
// l'énoncé au lieu du champ réel `enonce`.

class DevoirItem {
  final int id;
  final String titre;
  final String description;
  final String typeDevoir;
  final String matiere;
  final String niveau;
  final DateTime dateDebut;
  final DateTime dateLimite;
  final int dureeMinutes;
  final double noteSur;
  final double coefficient;
  final String? statutApprenant;
  final double? noteApprenant;
  final int tempsRestantJours;
  final bool estOuvert;
  final bool estExpire;
  final bool estPublie;
  final int nbQuestions;

  DevoirItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeDevoir,
    required this.matiere,
    required this.niveau,
    required this.dateDebut,
    required this.dateLimite,
    required this.dureeMinutes,
    required this.noteSur,
    required this.coefficient,
    this.statutApprenant,
    this.noteApprenant,
    required this.tempsRestantJours,
    required this.estOuvert,
    required this.estExpire,
    required this.estPublie,
    required this.nbQuestions,
  });

  factory DevoirItem.fromJson(Map<String, dynamic> json) {
    return DevoirItem(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      typeDevoir: json['type_devoir'] ?? 'cursus',
      matiere: json['matiere'] ?? '',
      niveau: json['niveau'] ?? '',
      dateDebut: DateTime.tryParse(json['date_debut'] ?? '') ?? DateTime.now(),
      dateLimite: DateTime.tryParse(json['date_limite'] ?? '') ?? DateTime.now(),
      dureeMinutes: json['duree_minutes'] ?? 60,
      noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      statutApprenant: json['statut_apprenant'],
      noteApprenant: (json['note_apprenant'] as num?)?.toDouble(),
      tempsRestantJours: json['temps_restant_jours'] ?? 0,
      estOuvert: json['est_ouvert'] ?? false,
      estExpire: json['est_expire'] ?? false,
      estPublie: json['est_publie'] ?? false,
      nbQuestions: json['nb_questions'] ?? 0,
    );
  }

  /// Round-trip vers JSON — `OfflineService.cacheDevoirs` stocke des
  /// `Map` brutes (P11.2 : `DevoirRepository.listMine()` renvoie
  /// désormais des `DevoirItem` déjà parsés, plus le JSON brut du réseau).
  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'description': description,
    'type_devoir': typeDevoir,
    'matiere': matiere,
    'niveau': niveau,
    'date_debut': dateDebut.toIso8601String(),
    'date_limite': dateLimite.toIso8601String(),
    'duree_minutes': dureeMinutes,
    'note_sur': noteSur,
    'coefficient': coefficient,
    'statut_apprenant': statutApprenant,
    'note_apprenant': noteApprenant,
    'temps_restant_jours': tempsRestantJours,
    'est_ouvert': estOuvert,
    'est_expire': estExpire,
    'est_publie': estPublie,
    'nb_questions': nbQuestions,
  };

  bool get aSoumis => statutApprenant != null && statutApprenant != 'non_commence';
  bool get estCorrige => statutApprenant == 'corrige';
  bool get estEnCours => statutApprenant == 'en_cours';

  String get statutLabel {
    switch (statutApprenant) {
      case 'non_commence':
        return 'À faire';
      case 'en_cours':
        return 'En cours';
      case 'soumis':
        return 'Soumis';
      case 'corrige':
        return 'Corrigé';
      case 'en_retard':
        return 'En retard';
      default:
        return 'À faire';
    }
  }

  String get typeLabel {
    switch (typeDevoir) {
      case 'cursus':
        return 'Cursus';
      case 'concours':
        return 'Concours';
      case 'formation_classique':
        return 'Formation';
      case 'formation_metier':
        return 'Métier';
      case 'olympiade':
        return 'Olympiade';
      default:
        return typeDevoir;
    }
  }
}
