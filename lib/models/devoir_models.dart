// lib/models/devoir_models.dart
//
// Modèles pour l'écran de gestion enseignant des devoirs (P7.4). Même
// convention que `exercice_models.dart` (P6.5) : un fichier neuf plutôt
// que la réutilisation des deux jeux de modèles existants
// (`lib/views/pages/apprenants/devoir_models.dart`, apprenant seul, et
// les classes internes de l'ancien `devoirs_cours_page.dart`) — aucun
// des deux n'a `EnonceDevoir`/`ChoixReponse` (avec `estCorrect`).

/// Un choix de réponse — vue ENSEIGNANT (porte `estCorrect`, jamais
/// exposé côté apprenant).
class ChoixReponseItem {
  const ChoixReponseItem({required this.id, required this.texte, required this.estCorrect});

  final int id;
  final String texte;
  final bool estCorrect;

  factory ChoixReponseItem.fromJson(Map<String, dynamic> json) => ChoixReponseItem(
    id: json['id'] as int? ?? 0,
    texte: json['texte'] as String? ?? '',
    estCorrect: json['est_correct'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'texte': texte, 'est_correct': estCorrect};
}

/// Une question — vue ENSEIGNANT (`QuestionDevoirAdminSerializer` :
/// `reponseAttendue`/`reponseExemple`/`choix[].estCorrect` inclus,
/// `enonceDevoirId` pour le regroupement PAR énoncé, P7.4).
class QuestionDevoirItem {
  const QuestionDevoirItem({
    required this.id,
    required this.enonce,
    required this.typeQuestion,
    required this.points,
    required this.ordre,
    required this.choix,
    required this.reponseAttendue,
    required this.reponseExemple,
    required this.enonceDevoirId,
  });

  final int id;
  final String enonce;
  final String typeQuestion; // 'qcm' | 'texte'
  final double points;
  final int ordre;
  final List<ChoixReponseItem> choix;
  final String reponseAttendue;
  final String reponseExemple;
  final int? enonceDevoirId;

  bool get estQcm => typeQuestion == 'qcm';

  factory QuestionDevoirItem.fromJson(Map<String, dynamic> json) => QuestionDevoirItem(
    id: json['id'] as int? ?? 0,
    enonce: json['enonce'] as String? ?? '',
    typeQuestion: json['type_question'] as String? ?? 'texte',
    points: (json['points'] as num?)?.toDouble() ?? 1.0,
    ordre: (json['ordre'] as num?)?.toInt() ?? 1,
    reponseAttendue: json['reponse_attendue'] as String? ?? '',
    reponseExemple: json['reponse_exemple'] as String? ?? '',
    enonceDevoirId: (json['enonce_devoir'] as num?)?.toInt(),
    choix: (json['choix'] as List? ?? [])
        .map((c) => ChoixReponseItem.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
  );
}

/// Un énoncé — regroupe ses propres questions (P7.1 : « un énoncé a
/// plusieurs questions, CES questions »). Les questions y sont
/// injectées côté client (voir `DevoirDetailController`) car
/// `EnonceDevoirSerializer` (liste des énoncés) et
/// `QuestionDevoirAdminSerializer` (liste des questions) sont deux
/// appels distincts côté backend.
class EnonceDevoirItem {
  const EnonceDevoirItem({
    required this.id,
    required this.contenu,
    required this.ordre,
    this.questions = const [],
  });

  final int id;
  final String contenu;
  final int ordre;
  final List<QuestionDevoirItem> questions;

  EnonceDevoirItem copyWith({List<QuestionDevoirItem>? questions}) => EnonceDevoirItem(
    id: id,
    contenu: contenu,
    ordre: ordre,
    questions: questions ?? this.questions,
  );

  factory EnonceDevoirItem.fromJson(Map<String, dynamic> json) => EnonceDevoirItem(
    id: json['id'] as int? ?? 0,
    contenu: json['contenu'] as String? ?? '',
    ordre: (json['ordre'] as num?)?.toInt() ?? 1,
  );
}

/// Résumé de la soumission de l'utilisateur courant pour un devoir
/// (`DevoirsCoursView.ma_soumission`) — `null` si pas encore démarré.
class MaSoumissionResume {
  const MaSoumissionResume({
    required this.id,
    required this.statut,
    required this.note,
    required this.soumisLe,
    required this.estCorrige,
    required this.commentaire,
  });

  final int id;
  final String statut;
  final double? note;
  final DateTime? soumisLe;
  final bool estCorrige;
  final String commentaire;

  factory MaSoumissionResume.fromJson(Map<String, dynamic> json) => MaSoumissionResume(
    id: json['id'] as int? ?? 0,
    statut: json['statut'] as String? ?? '',
    note: (json['note'] as num?)?.toDouble(),
    soumisLe: json['soumis_le'] != null ? DateTime.tryParse(json['soumis_le'] as String) : null,
    estCorrige: json['est_corrige'] as bool? ?? false,
    commentaire: json['commentaire'] as String? ?? '',
  );
}

/// Statistiques enseignant d'un devoir (`DevoirsCoursView.stats`) —
/// `null` côté apprenant.
class DevoirStats {
  const DevoirStats({required this.nbSoumissions, required this.nbCorriges, required this.moyenne});

  final int nbSoumissions;
  final int nbCorriges;
  final double moyenne;

  factory DevoirStats.fromJson(Map<String, dynamic> json) => DevoirStats(
    nbSoumissions: (json['nb_soumissions'] as num?)?.toInt() ?? 0,
    nbCorriges: (json['nb_corriges'] as num?)?.toInt() ?? 0,
    moyenne: (json['moyenne'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Un devoir dans la liste de l'onglet « Devoirs » d'un cours
/// (`GET /cours/<id>/devoirs/`) — vue combinée apprenant/enseignant,
/// comme `ExerciceListItem` (P6.5).
class DevoirListItem {
  const DevoirListItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDebut,
    required this.dateLimite,
    required this.estOuvert,
    required this.estExpire,
    required this.estPublie,
    required this.nbQuestions,
    required this.noteSur,
    required this.coefficient,
    required this.dureeMinutes,
    required this.tentativesMax,
    required this.typeCorrection,
    this.fichierCorrectionUrl,
    this.maSoumission,
    this.stats,
  });

  final int id;
  final String titre;
  final String description;
  final DateTime? dateDebut;
  final DateTime? dateLimite;
  final bool estOuvert;
  final bool estExpire;
  final bool estPublie;
  final int nbQuestions;
  final double noteSur;
  final double coefficient;
  final int dureeMinutes;
  final int tentativesMax;
  final String typeCorrection; // 'auto' | 'manuel'
  final String? fichierCorrectionUrl;
  final MaSoumissionResume? maSoumission;
  final DevoirStats? stats;

  bool get estManuel => typeCorrection == 'manuel';

  factory DevoirListItem.fromJson(Map<String, dynamic> json) => DevoirListItem(
    id: json['id'] as int,
    titre: json['titre'] as String? ?? '',
    description: json['description'] as String? ?? '',
    dateDebut: json['date_debut'] != null ? DateTime.tryParse(json['date_debut'] as String) : null,
    dateLimite: json['date_limite'] != null
        ? DateTime.tryParse(json['date_limite'] as String)
        : null,
    estOuvert: json['est_ouvert'] as bool? ?? false,
    estExpire: json['est_expire'] as bool? ?? false,
    estPublie: json['est_publie'] as bool? ?? false,
    nbQuestions: (json['nb_questions'] as num?)?.toInt() ?? 0,
    noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
    coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
    dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 60,
    tentativesMax: (json['tentatives_max'] as num?)?.toInt() ?? 1,
    typeCorrection: json['type_correction'] as String? ?? 'auto',
    fichierCorrectionUrl: json['fichier_correction_url'] as String?,
    maSoumission: json['ma_soumission'] != null
        ? MaSoumissionResume.fromJson(Map<String, dynamic>.from(json['ma_soumission'] as Map))
        : null,
    stats: json['stats'] != null
        ? DevoirStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map))
        : null,
  );
}

/// Une soumission dans la liste enseignant (`GET /devoirs/<id>/soumissions/`).
class SoumissionDevoirItem {
  const SoumissionDevoirItem({
    required this.id,
    required this.apprenantNom,
    required this.apprenantUsername,
    required this.statut,
    required this.note,
    required this.soumisLe,
    required this.estSuspecte,
    required this.nbFocusPerdu,
    required this.commentaire,
  });

  final int id;
  final String apprenantNom;
  final String apprenantUsername;
  final String statut;
  final double? note;
  final DateTime? soumisLe;
  final bool estSuspecte;
  final int nbFocusPerdu;
  final String commentaire;

  factory SoumissionDevoirItem.fromJson(Map<String, dynamic> json) => SoumissionDevoirItem(
    id: json['id'] as int? ?? 0,
    apprenantNom: json['apprenant_nom'] as String? ?? '',
    apprenantUsername: json['apprenant_username'] as String? ?? '',
    statut: json['statut'] as String? ?? '',
    note: (json['note'] as num?)?.toDouble(),
    soumisLe: json['soumis_le'] != null ? DateTime.tryParse(json['soumis_le'] as String) : null,
    estSuspecte: json['est_suspecte'] as bool? ?? false,
    nbFocusPerdu: (json['nb_focus_perdu'] as num?)?.toInt() ?? 0,
    commentaire: json['commentaire'] as String? ?? '',
  );
}

// ── Vue APPRENANT — composition d'un devoir (P7.5) ──────────────────────
//
// Distincts des classes enseignant ci-dessus (`ChoixReponseItem` porte
// `estCorrect`, `QuestionDevoirItem` porte `reponseAttendue`/`reponseExemple`)
// : jamais exposés par `QuestionDevoirSerializer`/`ChoixReponseSerializer`
// (vue apprenant, backend) — même séparation déjà actée en P6.4 entre
// `ChoixAPasser`/`QuestionAPasser` (apprenant) et `ChoixQuestion`/
// `QuestionExercice` (enseignant), `exercice_models.dart`.

/// Un choix de réponse — vue APPRENANT (`ChoixReponseSerializer` :
/// `id`/`texte` seulement, jamais `est_correct`).
class ChoixDevoirComposer {
  const ChoixDevoirComposer({required this.id, required this.texte});

  final int id;
  final String texte;

  factory ChoixDevoirComposer.fromJson(Map<String, dynamic> json) =>
      ChoixDevoirComposer(id: json['id'] as int? ?? 0, texte: json['texte'] as String? ?? '');
}

/// Une question — vue APPRENANT (`QuestionDevoirSerializer` :
/// `id`/`enonce`/`type_question`/`points`/`ordre`/`choix`, jamais
/// `reponse_attendue`/`reponse_exemple`/`choix[].est_correct`).
class QuestionDevoirComposer {
  const QuestionDevoirComposer({
    required this.id,
    required this.enonce,
    required this.typeQuestion,
    required this.points,
    required this.ordre,
    required this.choix,
  });

  final int id;
  final String enonce;
  final String typeQuestion; // 'qcm' | 'texte'
  final double points;
  final int ordre;
  final List<ChoixDevoirComposer> choix;

  bool get estQcm => typeQuestion == 'qcm';

  factory QuestionDevoirComposer.fromJson(Map<String, dynamic> json) => QuestionDevoirComposer(
    id: json['id'] as int? ?? 0,
    enonce: json['enonce'] as String? ?? '',
    typeQuestion: json['type_question'] as String? ?? 'texte',
    points: (json['points'] as num?)?.toDouble() ?? 1.0,
    ordre: (json['ordre'] as num?)?.toInt() ?? 1,
    choix: (json['choix'] as List? ?? [])
        .map((c) => ChoixDevoirComposer.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
  );
}

/// Un énoncé — porte déjà SES questions (`EnonceDevoirSerializer`, P7.1 —
/// contrairement à la vue enseignant ci-dessus, pas de regroupement
/// manuel côté client nécessaire).
class EnonceDevoirComposer {
  const EnonceDevoirComposer({
    required this.id,
    required this.contenu,
    required this.ordre,
    required this.questions,
  });

  final int id;
  final String contenu;
  final int ordre;
  final List<QuestionDevoirComposer> questions;

  factory EnonceDevoirComposer.fromJson(Map<String, dynamic> json) => EnonceDevoirComposer(
    id: json['id'] as int? ?? 0,
    contenu: json['contenu'] as String? ?? '',
    ordre: (json['ordre'] as num?)?.toInt() ?? 1,
    questions: (json['questions'] as List? ?? [])
        .map((q) => QuestionDevoirComposer.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
  );
}

/// Devoir à composer — `DevoirDetailSerializer` (`GET /devoirs/<id>/`).
/// `nbSorties`/`tentativesMax` sont ceux du CHARGEMENT : la sortie
/// (`DevoirRepository.sortir`) ne rafraîchit jamais cet objet, l'écran se
/// ferme aussitôt la confirmation obtenue (même patron que
/// `ExerciceAPasser`, P6.4).
class DevoirAComposer {
  const DevoirAComposer({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeDevoir,
    required this.dateDebut,
    required this.dateLimite,
    required this.dureeMinutes,
    required this.noteSur,
    required this.coefficient,
    required this.typeCorrection,
    required this.tentativesMax,
    required this.nbSorties,
    required this.enonces,
  });

  final int id;
  final String titre;
  final String description;

  /// `DevoirDetailSerializer.type_devoir` — un devoir d'olympiade
  /// (`'olympiade'`) est composé sur ce MÊME écran (`olympiades_page.dart`
  /// route vers `AppRoute.devoirComposer` en phase de compétition), mais
  /// avec un mode immersif dédié (voir `estOlympiade` ci-dessous) : NE PAS
  /// confondre avec le mode « question par question » de l'ancien écran
  /// (`_qParQ`), lui réellement mort (dépendait d'un champ imbriqué,
  /// `data['olympiade']['question_par_question']`, que le backend ne
  /// renvoie en réalité jamais — confirmé, non reconduit).
  final String typeDevoir;
  final DateTime? dateDebut;
  final DateTime? dateLimite;
  final int dureeMinutes;
  final double noteSur;
  final double coefficient;
  final String typeCorrection; // 'auto' | 'manuel'
  final int tentativesMax;
  final int nbSorties;
  final List<EnonceDevoirComposer> enonces;

  bool get estOlympiade => typeDevoir == 'olympiade';

  List<QuestionDevoirComposer> get toutesLesQuestions =>
      enonces.expand((e) => e.questions).toList();

  factory DevoirAComposer.fromJson(Map<String, dynamic> json) => DevoirAComposer(
    id: json['id'] as int? ?? 0,
    titre: json['titre'] as String? ?? 'Devoir',
    description: json['description'] as String? ?? '',
    typeDevoir: json['type_devoir'] as String? ?? 'normal',
    dateDebut: json['date_debut'] != null ? DateTime.tryParse(json['date_debut'] as String) : null,
    dateLimite: json['date_limite'] != null
        ? DateTime.tryParse(json['date_limite'] as String)
        : null,
    dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 60,
    noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
    coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
    typeCorrection: json['type_correction'] as String? ?? 'auto',
    tentativesMax: (json['sorties_max'] as num?)?.toInt() ?? 1,
    nbSorties: (json['nb_sorties'] as num?)?.toInt() ?? 0,
    enonces: (json['enonces'] as List? ?? [])
        .map((e) => EnonceDevoirComposer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

// ── Vue APPRENANT — résultat d'un devoir corrigé (P7.6) ──────────────────
//
// Distinct de `ChoixDevoirComposer` (composition, jamais `estCorrect`) :
// une fois corrigé, `QuestionDevoirSerializer` n'est plus la source —
// `SoumissionResultatSerializer.get_questions_detail` (backend) renvoie un
// snapshot COMPLET par question, `est_correct` inclus par choix, précisément
// pour que l'apprenant voie TOUTES les options et laquelle était correcte
// (corrigé en P7.3 — cause probable du bug historique « l'apprenant ne voit
// pas la bonne réponse »).

/// Un choix, snapshot post-correction — `estCorrect` y est légitime
/// (contrairement à `ChoixDevoirComposer`, composition en cours).
class ChoixResultatDevoir {
  const ChoixResultatDevoir({required this.id, required this.texte, required this.estCorrect});

  final int id;
  final String texte;
  final bool estCorrect;

  factory ChoixResultatDevoir.fromJson(Map<String, dynamic> json) => ChoixResultatDevoir(
    id: json['id'] as int? ?? 0,
    texte: json['texte'] as String? ?? '',
    estCorrect: json['est_correct'] as bool? ?? false,
  );
}

/// Détail de correction d'une question — `SoumissionResultatSerializer.get_questions_detail`.
class DetailReponseDevoir {
  const DetailReponseDevoir({
    required this.questionId,
    required this.questionEnonce,
    required this.typeQuestion,
    required this.reponseUtilisateur,
    required this.choixSelectionne,
    required this.choix,
    required this.estCorrect,
    required this.pointsObtenus,
    required this.pointsMax,
    required this.bonneReponse,
    required this.reponseExemple,
    required this.commentaireEnseignant,
  });

  final int questionId;
  final String questionEnonce;
  final String typeQuestion; // 'qcm' | 'texte'
  final String reponseUtilisateur;
  final String? choixSelectionne;
  final List<ChoixResultatDevoir> choix;

  /// `null` = pas encore corrigée manuellement (devoir en correction
  /// manuelle, question de type texte) — à distinguer explicitement de
  /// `false` (corrigée, incorrecte). NE PAS traiter comme faux.
  final bool? estCorrect;

  /// `null` tant que `estCorrect` est `null` (voir ci-dessus).
  final double? pointsObtenus;
  final double pointsMax;
  final String? bonneReponse;
  final String reponseExemple;

  /// = `ResultatDevoir.commentaire`, recopié ICI par le backend sur
  /// chaque question (pas de champ dédié par question dans le modèle) —
  /// ne jamais l'afficher par question dans l'UI (répétition visuelle
  /// du même texte), seulement une fois au niveau du résultat.
  final String commentaireEnseignant;

  bool get estQcm => typeQuestion == 'qcm';

  factory DetailReponseDevoir.fromJson(Map<String, dynamic> json) => DetailReponseDevoir(
    questionId: json['question_id'] as int? ?? 0,
    questionEnonce: json['question_enonce'] as String? ?? '',
    typeQuestion: json['type_question'] as String? ?? 'texte',
    reponseUtilisateur: json['reponse_utilisateur'] as String? ?? '',
    choixSelectionne: json['choix_selectionne'] as String?,
    choix: (json['choix'] as List? ?? [])
        .map((c) => ChoixResultatDevoir.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
    estCorrect: json['est_correct'] as bool?,
    pointsObtenus: (json['points_obtenus'] as num?)?.toDouble(),
    pointsMax: (json['points_max'] as num?)?.toDouble() ?? 0.0,
    bonneReponse: json['bonne_reponse'] as String?,
    reponseExemple: json['reponse_exemple'] as String? ?? '',
    commentaireEnseignant: json['commentaire_enseignant'] as String? ?? '',
  );
}

/// Résultat d'un devoir corrigé — `SoumissionResultatSerializer`
/// (`GET /devoirs/<id>/resultat/`, réponse 200 uniquement : la réponse
/// 202 « en attente de correction » n'a que `{'detail': '...'}`, jamais
/// cette forme — voir `ResultatDevoirController`).
class ResultatDevoir {
  const ResultatDevoir({
    required this.devoirTitre,
    required this.statut,
    required this.note,
    required this.noteSur,
    required this.commentaire,
    required this.soumisLe,
    required this.corrigeLe,
    required this.estEnRetard,
    required this.estSuspecte,
    required this.fichierCorrectionUrl,
    required this.questionsDetail,
  });

  final String devoirTitre;
  final String statut; // 'soumis' | 'en_retard' | 'corrige'

  /// `null` = pas encore noté (devoir en correction manuelle, même si le
  /// statut HTTP est 200 — voir le piège backend documenté dans
  /// `ResultatDevoirController.charger`).
  final double? note;
  final double noteSur;
  final String commentaire;
  final DateTime? soumisLe;
  final DateTime? corrigeLe;
  final bool estEnRetard;

  /// Préoccupation ENSEIGNANT (anti-triche, `SoumissionsSheet`, P7.4) —
  /// jamais affiché à l'apprenant lui-même, conservé ici pour fidélité au
  /// modèle de données, pas pour l'UI.
  final bool estSuspecte;
  final String? fichierCorrectionUrl;
  final List<DetailReponseDevoir> questionsDetail;

  factory ResultatDevoir.fromJson(Map<String, dynamic> json) => ResultatDevoir(
    devoirTitre: json['devoir_titre'] as String? ?? 'Devoir',
    statut: json['statut'] as String? ?? '',
    note: (json['note'] as num?)?.toDouble(),
    noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
    commentaire: json['commentaire'] as String? ?? '',
    soumisLe: json['soumis_le'] != null ? DateTime.tryParse(json['soumis_le'] as String) : null,
    corrigeLe: json['corrige_le'] != null ? DateTime.tryParse(json['corrige_le'] as String) : null,
    estEnRetard: json['est_en_retard'] as bool? ?? false,
    estSuspecte: json['est_suspecte'] as bool? ?? false,
    fichierCorrectionUrl: json['fichier_correction_url'] as String?,
    questionsDetail: (json['questions_detail'] as List? ?? [])
        .map((d) => DetailReponseDevoir.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList(),
  );
}
