// lib/models/exercice_models.dart
//
// Modèles pour l'écran « passer un exercice » (P6.4). Remplace les
// `Map<String, dynamic>` bruts utilisés jusqu'ici — premier vrai modèle
// Dart pour Exercice/Question (contrairement au devoir, qui avait déjà
// devoir_models.dart).

class ChoixAPasser {
  const ChoixAPasser({required this.id, required this.texte, required this.estCorrect});

  final int id;
  final String texte;
  final bool estCorrect;

  factory ChoixAPasser.fromJson(Map<String, dynamic> json) => ChoixAPasser(
        id: json['id'] as int? ?? 0,
        texte: json['texte'] as String? ?? '',
        estCorrect: json['est_correct'] as bool? ?? false,
      );
}

class QuestionAPasser {
  const QuestionAPasser({
    required this.id,
    required this.text,
    required this.type,
    required this.points,
    required this.choix,
  });

  final int id;
  final String text;
  final String type; // 'qcm' | 'texte'
  final double points;
  final List<ChoixAPasser> choix;

  bool get estQcm => type == 'qcm';

  factory QuestionAPasser.fromJson(Map<String, dynamic> json) => QuestionAPasser(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        type: json['type'] as String? ?? 'texte',
        points: (json['points'] as num?)?.toDouble() ?? 0.0,
        choix: (json['choix'] as List? ?? [])
            .map((c) => ChoixAPasser.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );
}

/// Exercice à passer (issu de `GET /api/exercices/<id>/` combiné à
/// `POST /api/exercices/<id>/demarrer/`).
class ExerciceAPasser {
  const ExerciceAPasser({
    required this.id,
    required this.titre,
    required this.enonce,
    required this.dureeMinutes,
    required this.dureeTotaleSecondes,
    required this.tempsRestantSecondes,
    required this.tentativesMax,
    required this.tentativesRestantes,
    required this.questions,
  });

  final int id;
  final String titre;
  final String enonce;
  final int dureeMinutes;
  final int dureeTotaleSecondes;
  final int tempsRestantSecondes;
  final int tentativesMax;
  final int tentativesRestantes;
  final List<QuestionAPasser> questions;

  bool get tentativesEpuisees => tentativesRestantes <= 0;

  factory ExerciceAPasser.fromDetailJson(Map<String, dynamic> json) => ExerciceAPasser(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? 'Exercice',
        enonce: json['enonce'] as String? ?? '',
        dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 10,
        dureeTotaleSecondes: (json['duree_totale'] as num?)?.toInt() ?? 0,
        tempsRestantSecondes: (json['temps_restant'] as num?)?.toInt() ?? 0,
        tentativesMax: (json['tentatives_max'] as num?)?.toInt() ?? 1,
        tentativesRestantes: (json['tentatives_restantes'] as num?)?.toInt() ?? 0,
        questions: (json['questions'] as List? ?? [])
            .map((q) => QuestionAPasser.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList(),
      );

  ExerciceAPasser copyWith({int? dureeTotaleSecondes, int? tempsRestantSecondes}) => ExerciceAPasser(
        id: id,
        titre: titre,
        enonce: enonce,
        dureeMinutes: dureeMinutes,
        dureeTotaleSecondes: dureeTotaleSecondes ?? this.dureeTotaleSecondes,
        tempsRestantSecondes: tempsRestantSecondes ?? this.tempsRestantSecondes,
        tentativesMax: tentativesMax,
        tentativesRestantes: tentativesRestantes,
        questions: questions,
      );
}

/// Détail d'une correction par question — normalise les DEUX formes
/// renvoyées par le backend pour le même concept (P6.2) : la soumission
/// immédiate (`detail`, clés `correct`/`reponse_utilisateur`) et
/// l'historique (`historique[].reponses`, clés `est_correct`/`reponse`).
/// Un seul modèle Dart, deux constructeurs nommés — jamais deux
/// conventions de clés dans l'UI.
class DetailReponse {
  const DetailReponse({
    required this.questionId,
    required this.enonce,
    required this.reponseApprenant,
    required this.bonneReponse,
    required this.estCorrect,
    required this.pointsObtenus,
    required this.pointsMax,
    required this.explication,
  });

  final int questionId;
  final String enonce;
  final String reponseApprenant;
  final String bonneReponse;
  final bool estCorrect;
  final double pointsObtenus;
  final double pointsMax;
  final String explication;

  factory DetailReponse.fromSoumission(Map<String, dynamic> json) => DetailReponse(
        questionId: json['question_id'] as int? ?? 0,
        enonce: json['question'] as String? ?? '',
        reponseApprenant: json['reponse_utilisateur'] as String? ?? '',
        bonneReponse: json['bonne_reponse'] as String? ?? '',
        estCorrect: json['correct'] as bool? ?? false,
        pointsObtenus: (json['points_obtenus'] as num?)?.toDouble() ?? 0.0,
        pointsMax: (json['points_max'] as num?)?.toDouble() ?? 0.0,
        explication: json['explication'] as String? ?? '',
      );

  factory DetailReponse.fromHistorique(Map<String, dynamic> json) => DetailReponse(
        questionId: json['question_id'] as int? ?? 0,
        enonce: json['question'] as String? ?? '',
        reponseApprenant: json['reponse'] as String? ?? '',
        bonneReponse: json['bonne_reponse'] as String? ?? '',
        estCorrect: json['est_correct'] as bool? ?? false,
        pointsObtenus: (json['points_obtenus'] as num?)?.toDouble() ?? 0.0,
        pointsMax: (json['points_max'] as num?)?.toDouble() ?? 0.0,
        explication: json['explication'] as String? ?? '',
      );
}

class TentativeHistorique {
  const TentativeHistorique({
    required this.id,
    required this.tentativeNumero,
    required this.date,
    required this.score,
    required this.total,
    required this.noteSur20,
    required this.estSoumise,
    required this.reponses,
  });

  final int id;
  final int tentativeNumero;
  final DateTime date;
  final double score;
  final double total;
  final double noteSur20;
  final bool estSoumise;
  final List<DetailReponse> reponses;

  factory TentativeHistorique.fromJson(Map<String, dynamic> json) => TentativeHistorique(
        id: json['id'] as int? ?? 0,
        tentativeNumero: (json['tentative_numero'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        noteSur20: (json['note_sur_20'] as num?)?.toDouble() ?? 0.0,
        estSoumise: json['est_soumise'] as bool? ?? false,
        reponses: (json['reponses'] as List? ?? [])
            .map((d) => DetailReponse.fromHistorique(Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}

/// Réponse de `GET /api/evaluations/exercice/<id>/` — note officielle
/// (dernière tentative valide) + historique complet des tentatives.
class ResultatExercice {
  const ResultatExercice({
    required this.exerciceId,
    required this.exerciceTitre,
    required this.note,
    required this.noteSur,
    required this.score,
    required this.total,
    required this.detail,
    required this.historique,
    required this.tentativesRestantes,
    required this.tentativesMax,
    required this.tentativesEpuisees,
  });

  final int exerciceId;
  final String exerciceTitre;
  final double note;
  final double noteSur;
  final double score;
  final double total;
  final List<DetailReponse> detail;
  final List<TentativeHistorique> historique;
  final int tentativesRestantes;
  final int tentativesMax;
  final bool tentativesEpuisees;

  factory ResultatExercice.fromJson(Map<String, dynamic> json) => ResultatExercice(
        exerciceId: json['exercice_id'] as int? ?? 0,
        exerciceTitre: json['exercice_titre'] as String? ?? 'Exercice',
        note: (json['note'] as num?)?.toDouble() ?? 0.0,
        noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        detail: (json['detail'] as List? ?? [])
            .map((d) => DetailReponse.fromSoumission(Map<String, dynamic>.from(d as Map)))
            .toList(),
        historique: (json['historique'] as List? ?? [])
            .map((t) => TentativeHistorique.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        tentativesRestantes: (json['tentatives_restantes'] as num?)?.toInt() ?? 0,
        tentativesMax: (json['tentatives_max'] as num?)?.toInt() ?? 1,
        tentativesEpuisees: json['tentatives_epuisees'] as bool? ?? false,
      );
}

/// Réponse de `POST /api/exercices/<id>/evaluer/` ou `.../sortir/`.
/// `rangGagne`/`ancienRang`/`nouveauRang` sont absents (`null`) si le
/// rang ne s'est pas amélioré (P6.3) — présents uniquement en cas de
/// gain, jamais une valeur fixe à vérifier avec `== true` sans null-check.
class SoumissionExercice {
  const SoumissionExercice({
    required this.score,
    required this.total,
    required this.note,
    required this.noteSur,
    required this.detail,
    required this.tentativeNumero,
    required this.tentativesRestantes,
    required this.tentativesEpuisees,
    required this.message,
    required this.autoSoumis,
    this.rangGagne,
    this.ancienRang,
    this.nouveauRang,
  });

  final double score;
  final double total;
  final double note;
  final double noteSur;
  final List<DetailReponse> detail;
  final int tentativeNumero;
  final int tentativesRestantes;
  final bool tentativesEpuisees;
  final String message;
  final bool autoSoumis;
  final bool? rangGagne;
  final int? ancienRang;
  final int? nouveauRang;

  factory SoumissionExercice.fromJson(Map<String, dynamic> json) => SoumissionExercice(
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        note: (json['note'] as num?)?.toDouble() ?? 0.0,
        noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
        detail: (json['detail'] as List? ?? [])
            .map((d) => DetailReponse.fromSoumission(Map<String, dynamic>.from(d as Map)))
            .toList(),
        tentativeNumero: (json['tentative_numero'] as num?)?.toInt() ?? 0,
        tentativesRestantes: (json['tentatives_restantes'] as num?)?.toInt() ?? 0,
        tentativesEpuisees: json['tentatives_epuisees'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        autoSoumis: json['auto_soumis'] as bool? ?? false,
        rangGagne: json['rang_gagne'] as bool?,
        ancienRang: (json['ancien_rang'] as num?)?.toInt(),
        nouveauRang: (json['nouveau_rang'] as num?)?.toInt(),
      );
}

/// Une leçon d'un module — pour le dropdown de ciblage d'un exercice
/// (P6.5, `exercices_cours_page.dart`).
class LeconOption {
  const LeconOption({required this.id, required this.titre});

  final int id;
  final String titre;

  factory LeconOption.fromJson(Map<String, dynamic> json) => LeconOption(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? '',
      );
}

/// Un module d'un cours, avec ses leçons — pour les dropdowns de filtre
/// et de ciblage d'un exercice (P6.5).
class ModuleOption {
  const ModuleOption({required this.id, required this.titre, required this.lecons});

  final int id;
  final String titre;
  final List<LeconOption> lecons;

  factory ModuleOption.fromJson(Map<String, dynamic> json) => ModuleOption(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? '',
        lecons: (json['lecons'] as List? ?? [])
            .map((l) => LeconOption.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
      );
}

/// Un choix de réponse d'une question QCM, avec son statut de
/// correction — utilisé UNIQUEMENT côté enseignant (création/édition/
/// affichage de question). Distinct de [ChoixAPasser] (qui ne porte
/// jamais `estCorrect` vers l'apprenant, P6.4).
class ChoixQuestion {
  const ChoixQuestion({required this.texte, required this.estCorrect});

  final String texte;
  final bool estCorrect;

  factory ChoixQuestion.fromJson(Map<String, dynamic> json) => ChoixQuestion(
        texte: json['texte'] as String? ?? '',
        estCorrect: json['est_correct'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'texte': texte, 'est_correct': estCorrect};
}

/// Une question d'un exercice, vue enseignant (composition/consultation)
/// — distinct de [QuestionAPasser] (vue apprenant, ne révèle jamais
/// `est_correct`).
class QuestionExercice {
  const QuestionExercice({
    required this.id,
    required this.text,
    required this.typeQuestion,
    required this.points,
    required this.choix,
    required this.bonneReponse,
  });

  final int id;
  final String text;
  final String typeQuestion; // 'qcm' | 'texte'
  final double points;
  final List<ChoixQuestion> choix;
  final String bonneReponse;

  bool get estQcm => typeQuestion == 'qcm';

  factory QuestionExercice.fromJson(Map<String, dynamic> json) => QuestionExercice(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        typeQuestion: json['type'] as String? ?? 'texte',
        points: (json['points'] as num?)?.toDouble() ?? 1.0,
        bonneReponse: json['bonne_reponse'] as String? ?? '',
        choix: (json['choix'] as List? ?? [])
            .map((c) => ChoixQuestion.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );
}

/// Un exercice dans la liste de l'onglet « Exercices » d'un cours — vue
/// enseignant/apprenant combinée (P6.5). Distinct de [ExerciceAPasser]
/// (vue passage, sans les champs de composition/ciblage).
class ExerciceListItem {
  const ExerciceListItem({
    required this.id,
    required this.titre,
    required this.enonce,
    this.enonceImageUrl,
    required this.etoiles,
    required this.dureeMinutes,
    required this.tentativesMax,
    required this.nbQuestions,
    required this.typeExercice,
    required this.estEpreuve,
    this.moduleId,
    this.moduleNom,
    this.leconId,
    this.leconNom,
    this.exercicesComposes = const [],
  });

  final int id;
  final String titre;
  final String enonce;
  final String? enonceImageUrl;
  final int etoiles;
  final int dureeMinutes;
  final int tentativesMax;
  final int nbQuestions;
  final String typeExercice; // 'general' | 'module' | 'lecon' | 'epreuve'
  final bool estEpreuve;
  final int? moduleId;
  final String? moduleNom;
  final int? leconId;
  final String? leconNom;
  final List<Map<String, dynamic>> exercicesComposes;

  factory ExerciceListItem.fromJson(Map<String, dynamic> json) => ExerciceListItem(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? '',
        enonce: json['enonce'] as String? ?? '',
        enonceImageUrl: json['enonce_image_url'] as String?,
        etoiles: (json['etoiles'] as num?)?.toInt() ?? 1,
        dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 10,
        tentativesMax: (json['tentatives_max'] as num?)?.toInt() ?? 1,
        nbQuestions: (json['nb_questions'] as num?)?.toInt() ?? 0,
        typeExercice: json['type_exercice'] as String? ?? 'general',
        estEpreuve: json['est_epreuve'] as bool? ?? false,
        moduleId: (json['module'] as num?)?.toInt(),
        moduleNom: json['module_nom'] as String?,
        leconId: (json['lecon'] as num?)?.toInt(),
        leconNom: json['lecon_nom'] as String?,
        exercicesComposes: (json['exercices_composes_details'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
