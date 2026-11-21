// lib/models/olympiade_models.dart
//
// Modèles APPRENANT pour les olympiades (P8.3) — remplace l'usage
// apprenant de `OlympiadeItem` (`lib/views/pages/apprenants/formations_models.dart`),
// dont `fromJson` lit des clés qui n'existent plus dans la réponse réelle :
// `matiere`/`niveau` (retirés du modèle, P8.1) et surtout
// `prix_1er`/`prix_2eme`/`prix_3eme` pour construire `prixDescription` —
// le vrai champ, confirmé dans `OlympiadeListSerializer`
// (apps/evaluation/serializers.py), est `recompense` (texte riche,
// `YkRichEditor` côté création depuis P8.2). Résultat concret du bug :
// la section « Récompenses » affichée à l'apprenant montrait
// `" /  / "` (3 valeurs vides concaténées) au lieu du contenu réel.
// `OlympiadeItem` (formations_models.dart) reste utilisé ailleurs tant
// que ses autres appelants n'ont pas migré — non supprimé ici.

/// `mon_inscription` — résumé de l'inscription de l'apprenant connecté
/// (`null` si non inscrit).
class MonInscriptionOlympiade {
  const MonInscriptionOlympiade({
    required this.id,
    required this.note,
    required this.classement,
    required this.soumis,
    required this.statut,
  });

  final int id;
  final double? note;
  final int? classement;
  final bool soumis;
  final String statut;

  factory MonInscriptionOlympiade.fromJson(Map<String, dynamic> json) => MonInscriptionOlympiade(
    id: json['id'] as int? ?? 0,
    note: (json['note'] as num?)?.toDouble(),
    classement: json['classement'] as int?,
    soumis: json['soumis'] as bool? ?? false,
    statut: json['statut'] as String? ?? '',
  );
}

/// Une olympiade — vue APPRENANT (`OlympiadeListSerializer`/
/// `OlympiadeDetailSerializer`, `GET /olympiades/pour-moi/` ou
/// `GET /olympiades/<id>/`).
class OlympiadeApprenant {
  const OlympiadeApprenant({
    required this.id,
    required this.titre,
    required this.description,
    required this.edition,
    required this.dateOuvertureInscription,
    required this.dateClotureInscription,
    required this.dateDebutOlympiade,
    required this.dateFinOlympiade,
    required this.dureeMinutes,
    required this.nbQuestions,
    required this.noteSur,
    required this.recompense,
    required this.prixGlobal,
    required this.prixParticipation,
    required this.demandePaiementParticipants,
    required this.statut,
    required this.estInscrit,
    required this.nbInscrits,
    required this.inscriptionOuverte,
    required this.devoirId,
    required this.monInscription,
    required this.niveauxAccessibles,
  });

  final int id;
  final String titre;
  final String description;
  final String edition;
  final DateTime dateOuvertureInscription;
  final DateTime dateClotureInscription;
  final DateTime dateDebutOlympiade;
  final DateTime dateFinOlympiade;
  final int dureeMinutes;
  final int nbQuestions;
  final double noteSur;
  final String recompense;
  final int prixGlobal;
  final int prixParticipation;
  final bool demandePaiementParticipants;

  /// `statut_auto` backend — 'bientot' | 'inscription' | 'fermee' |
  /// 'en_cours' | 'terminee' (corrigé en P8.3, renvoyait auparavant des
  /// variantes accentuées ne correspondant à rien côté client).
  final String statut;
  final bool estInscrit;
  final int nbInscrits;
  final bool inscriptionOuverte;
  final int? devoirId;
  final MonInscriptionOlympiade? monInscription;
  final List<String> niveauxAccessibles;

  bool get afficherClassement => statut == 'terminee';

  factory OlympiadeApprenant.fromJson(Map<String, dynamic> json) => OlympiadeApprenant(
    id: json['id'] as int? ?? 0,
    titre: json['titre'] as String? ?? '',
    description: json['description'] as String? ?? '',
    edition: json['edition'] as String? ?? '',
    dateOuvertureInscription:
        DateTime.tryParse(json['date_ouverture_inscription'] as String? ?? '') ?? DateTime.now(),
    dateClotureInscription:
        DateTime.tryParse(json['date_cloture_inscription'] as String? ?? '') ?? DateTime.now(),
    dateDebutOlympiade: DateTime.tryParse(json['date_debut_olympiade'] as String? ?? '') ?? DateTime.now(),
    dateFinOlympiade: DateTime.tryParse(json['date_fin_olympiade'] as String? ?? '') ?? DateTime.now(),
    dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 120,
    nbQuestions: (json['nb_questions'] as num?)?.toInt() ?? 0,
    noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
    recompense: json['recompense'] as String? ?? '',
    prixGlobal: (json['prix_global'] as num?)?.toInt() ?? 0,
    prixParticipation: (json['prix_participation'] as num?)?.toInt() ?? 0,
    demandePaiementParticipants: json['demande_paiement_participants'] as bool? ?? false,
    statut: json['statut'] as String? ?? 'bientot',
    estInscrit: json['est_inscrit'] as bool? ?? false,
    nbInscrits: (json['nb_inscrits'] as num?)?.toInt() ?? 0,
    inscriptionOuverte: json['inscription_ouverte'] as bool? ?? false,
    devoirId: json['devoir_id'] as int?,
    monInscription: json['mon_inscription'] != null
        ? MonInscriptionOlympiade.fromJson(Map<String, dynamic>.from(json['mon_inscription'] as Map))
        : null,
    niveauxAccessibles: (json['niveaux_accessibles'] as List? ?? []).map((n) => n.toString()).toList(),
  );
}

/// Une ligne du classement — `ClassementOlympiadeSerializer`
/// (`GET /olympiades/<id>/classement/`, paginé).
class ClassementOlympiadeEntry {
  const ClassementOlympiadeEntry({
    required this.rang,
    required this.nomComplet,
    required this.username,
    required this.note,
    required this.noteSur20,
    required this.mention,
  });

  final int rang;
  final String nomComplet;
  final String username;
  final double note;
  final double noteSur20;
  final String mention;

  factory ClassementOlympiadeEntry.fromJson(Map<String, dynamic> json) => ClassementOlympiadeEntry(
    rang: (json['rang'] as num?)?.toInt() ?? 0,
    nomComplet: json['nom_complet'] as String? ?? '',
    username: json['username'] as String? ?? '',
    note: (json['note'] as num?)?.toDouble() ?? 0.0,
    noteSur20: (json['note_sur_20'] as num?)?.toDouble() ?? 0.0,
    mention: json['mention'] as String? ?? '',
  );
}
