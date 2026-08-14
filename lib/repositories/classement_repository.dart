import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Une ligne de classement (en cours ou archivée) — schéma commun aux deux
/// endpoints depuis le correctif P11.8 (`nom`/`username` étaient absents
/// de la réponse du classement en cours, alors que le frontend les lisait
/// déjà — bug confirmé et corrigé côté backend en même temps).
class ClassementLigne {
  const ClassementLigne({required this.apprenantId, required this.nom, required this.rang, required this.score, this.progression});

  final int apprenantId;
  final String nom;
  final int rang;
  final double score;

  /// `null` pour une ligne archivée (`ClassementHistorique` ne stocke pas
  /// de progression — c'est un instantané figé, pas une série).
  final double? progression;

  factory ClassementLigne.fromJson(Map<String, dynamic> json) => ClassementLigne(
    apprenantId: json['apprenant_id'] as int,
    nom: (json['nom'] as String?)?.isNotEmpty == true ? json['nom'] as String : (json['username']?.toString() ?? ''),
    rang: (json['rang'] as num?)?.toInt() ?? 0,
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    progression: (json['progression'] as num?)?.toDouble(),
  );
}

class ClassementDepartement {
  const ClassementDepartement({
    required this.departementNom,
    required this.classement,
    required this.totalParticipants,
    required this.moyenne,
    required this.meilleur,
  });

  final String departementNom;
  final List<ClassementLigne> classement;
  final int totalParticipants;
  final double moyenne;
  final double meilleur;

  /// `mon_rang` du backend n'est pas repris ici : sa forme (sans
  /// `apprenant_id`) empêcherait d'identifier la ligne "moi" dans
  /// `classement` pour la mise en avant `YkLeaderboardEntry.isCurrentUser`
  /// — l'appelant retrouve sa propre ligne par id utilisateur directement
  /// dans `classement`, qui la contient déjà.
  factory ClassementDepartement.fromJson(Map<String, dynamic> json) {
    final classement = (json['classement'] as List? ?? [])
        .map((e) => ClassementLigne.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final stats = Map<String, dynamic>.from(json['stats'] as Map? ?? {});
    return ClassementDepartement(
      departementNom: (json['departement'] as Map?)?['nom']?.toString() ?? '',
      classement: classement,
      totalParticipants: (stats['total'] as num?)?.toInt() ?? 0,
      moyenne: (stats['moyenne'] as num?)?.toDouble() ?? 0.0,
      meilleur: (stats['meilleur'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Une période de classement déjà archivée (`ClassementHistorique`) —
/// `periodeDebut` sert d'identifiant pour récupérer son détail complet.
class PeriodeArchivee {
  const PeriodeArchivee({required this.periodeDebut, required this.periodeFin});

  final DateTime periodeDebut;
  final DateTime periodeFin;

  factory PeriodeArchivee.fromJson(Map<String, dynamic> json) => PeriodeArchivee(
    periodeDebut: DateTime.parse(json['periode_debut'] as String),
    periodeFin: DateTime.parse(json['periode_fin'] as String),
  );
}

/// Classement/profil — nouveau en P11.8, aucune de ces routes n'était
/// consommée via un repository avant ce ticket (appels `http` bruts
/// dupliqués dans `classement_departement_page.dart`/`profil_page.dart`).
class ClassementRepository {
  final ApiClient _api;

  ClassementRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<ClassementDepartement> departement(int departementId) async {
    final data = await _api.get(EvaluationEndpoints.classementDepartement(departementId));
    return ClassementDepartement.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PeriodeArchivee>> periodesArchivees(int departementId) async {
    final data = await _api.get(EvaluationEndpoints.classementDepartementPeriodes(departementId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => PeriodeArchivee.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ClassementLigne>> classementArchive(int departementId, DateTime periodeDebut) async {
    final data = await _api.get(
      EvaluationEndpoints.classementDepartementHistorique(departementId),
      query: {'periode_debut': periodeDebut.toIso8601String()},
    );
    final classement = Map<String, dynamic>.from(data as Map)['classement'] as List? ?? [];
    return classement.map((e) => ClassementLigne.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Score/rang global de l'apprenant connecté — forme brute (schéma
  /// hétérogène, pas de modèle dédié pour un seul écran, `profil_page.dart`).
  Future<Map<String, dynamic>> monScore() async {
    final data = await _api.get(EvaluationEndpoints.classementMonScore);
    return Map<String, dynamic>.from(data as Map);
  }

  /// P17.14 : plancher réel du coefficient d'un devoir (poids
  /// `ParametreClassement` de la source `etoile_3`) — jamais codé en dur
  /// côté Dart (règle 3), toujours lu depuis le backend.
  Future<double> coefficientDevoirMinimum() async {
    final data = await _api.get(EvaluationEndpoints.classementCoefficientDevoirMinimum);
    final map = Map<String, dynamic>.from(data as Map);
    return (map['coefficient_min'] as num?)?.toDouble() ?? 0.1;
  }
}
