// devoir_models.dart
// Modèles Dart partagés entre toutes les pages devoirs

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

class ChoixDevoir {
  final int    id;
  final String texte;
  const ChoixDevoir({required this.id, required this.texte});
  factory ChoixDevoir.fromJson(Map j) =>
      ChoixDevoir(id: j['id'], texte: j['texte'] ?? '');
}

class QuestionDevoir {
  final int               id;
  final String            texte;
  final String            type;   // qcm | texte
  final int               points;
  final int               ordre;
  final List<ChoixDevoir> choix;

  const QuestionDevoir({
    required this.id,
    required this.texte,
    required this.type,
    required this.points,
    required this.ordre,
    required this.choix,
  });

  factory QuestionDevoir.fromJson(Map j) => QuestionDevoir(
    id:     j['id'],
    texte:  j['texte'] ?? '',
    type:   j['type_question'] ?? 'texte',
    points: j['points'] ?? 1,
    ordre:  j['ordre'] ?? 0,
    choix:  (j['choix'] as List? ?? [])
                .map((c) => ChoixDevoir.fromJson(c))
                .toList(),
  );
}

class DevoirDetail {
  final int                 id;
  final String              titre;
  final String              typeDevoir;
  final int                 dureeMinutes;
  final bool                questionParQuestion;
  final bool                tempsStrict;
  final int                 nbSortiesTolerees;
  final int?                tempsRestant;
  final List<QuestionDevoir> questions;

  const DevoirDetail({
    required this.id,
    required this.titre,
    required this.typeDevoir,
    required this.dureeMinutes,
    required this.questionParQuestion,
    required this.tempsStrict,
    required this.nbSortiesTolerees,
    this.tempsRestant,
    required this.questions,
  });

  factory DevoirDetail.fromJson(Map<String, dynamic> j) {
    final olymp = j['olympiade'];
    return DevoirDetail(
      id:                  j['id'],
      titre:               j['titre'] ?? '',
      typeDevoir:          j['type_devoir'] ?? 'cursus',
      dureeMinutes:        j['duree_minutes'] ?? 0,
      questionParQuestion: olymp?['question_par_question'] ?? false,
      tempsStrict:         olymp?['temps_strict'] ?? false,
      nbSortiesTolerees:   olymp?['nb_sorties_tolerees'] ?? 0,
      tempsRestant:        j['temps_restant'],
      questions:           (j['questions'] as List? ?? [])
                               .map((q) => QuestionDevoir.fromJson(q))
                               .toList(),
    );
  }

  bool get estOlympiade => typeDevoir == 'olympiade';
}
