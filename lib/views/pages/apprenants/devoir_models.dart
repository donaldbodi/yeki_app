// devoir_models.dart
// Modèles Dart partagés entre toutes les pages devoirs.
//
// P7.5 : `ChoixDevoir`/`QuestionDevoir`/`DevoirDetail` (vue composition
// apprenant) supprimés — 0 appelant restant (confirmé par recherche),
// remplacés par `ChoixDevoirComposer`/`QuestionDevoirComposer`/
// `DevoirAComposer` (`lib/models/devoir_models.dart`), qui corrigent au
// passage un bug réel : `QuestionDevoir.fromJson` lisait `j['texte']` pour
// l'énoncé au lieu du champ réel `enonce`. `DevoirModel`/`OlympiadeInfo`
// ci-dessous restent utilisés (dashboard `devoirs_page.dart`), inchangés.

class OlympiadeInfo {
  final int      id;
  final DateTime datFinInscription;
  final DateTime datDebutCompetition;
  final DateTime datFinCompetition;
  final bool     questionParQuestion;
  final bool     tempsStrict;
  final int      nbSortiesTolerees;
  final String   phaseActuelle;
  final String   reglement;
  final String   prixDescription;

  const OlympiadeInfo({
    required this.id,
    required this.datFinInscription,
    required this.datDebutCompetition,
    required this.datFinCompetition,
    required this.questionParQuestion,
    required this.tempsStrict,
    required this.nbSortiesTolerees,
    required this.phaseActuelle,
    required this.reglement,
    required this.prixDescription,
  });

  factory OlympiadeInfo.fromJson(Map<String, dynamic> j) => OlympiadeInfo(
    id:                   j['id'],
    datFinInscription:    DateTime.parse(j['date_fin_inscription']),
    datDebutCompetition:  DateTime.parse(j['date_debut_competition']),
    datFinCompetition:    DateTime.parse(j['date_fin_competition']),
    questionParQuestion:  j['question_par_question'] ?? true,
    tempsStrict:          j['temps_strict'] ?? true,
    nbSortiesTolerees:    j['nb_sorties_tolerees'] ?? 0,
    phaseActuelle:        j['phase_actuelle'] ?? 'inscription',
    reglement:            j['reglement'] ?? '',
    prixDescription:      j['prix_description'] ?? '',
  );
}

class DevoirModel {
  final int           id;
  final String        titre;
  final String        description;
  final String        typeDevoir;   // cursus|concours|formation|olympiade
  final String        matiere;
  final String        niveau;
  final String        concoursCible;
  final DateTime      dateOuverture;
  final DateTime      dateLimite;
  final int           dureeMinutes;
  final String?       fichierSujet;
  final bool          estOuvert;
  final bool          estTermine;
  final String        statut;       // en_attente|en_cours|soumis|corrige|hors_delai
  final int           nbQuestions;
  final int?          tempsRestant; // secondes
  final OlympiadeInfo? olympiade;

  const DevoirModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeDevoir,
    required this.matiere,
    required this.niveau,
    required this.concoursCible,
    required this.dateOuverture,
    required this.dateLimite,
    required this.dureeMinutes,
    this.fichierSujet,
    required this.estOuvert,
    required this.estTermine,
    required this.statut,
    required this.nbQuestions,
    this.tempsRestant,
    this.olympiade,
  });

  factory DevoirModel.fromJson(Map<String, dynamic> j) => DevoirModel(
    id:            j['id'],
    titre:         j['titre'] ?? '',
    description:   j['description'] ?? '',
    typeDevoir:    j['type_devoir'] ?? 'cursus',
    matiere:       j['matiere'] ?? '',
    niveau:        j['niveau'] ?? '',
    concoursCible: j['concours_cible'] ?? '',
    dateOuverture: DateTime.parse(j['date_ouverture']),
    dateLimite:    DateTime.parse(j['date_limite']),
    dureeMinutes:  j['duree_minutes'] ?? 0,
    fichierSujet:  j['fichier_sujet'],
    estOuvert:     j['est_ouvert'] ?? false,
    estTermine:    j['est_termine'] ?? false,
    statut:        j['statut'] ?? 'en_attente',
    nbQuestions:   j['nb_questions'] ?? 0,
    tempsRestant:  j['temps_restant'],
    olympiade:     j['olympiade'] != null
                   ? OlympiadeInfo.fromJson(j['olympiade'])
                   : null,
  );
}
