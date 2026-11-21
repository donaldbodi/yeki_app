// lib/models/repetiteur_models.dart
//
// Modèles répétiteurs — administration Service Client (P9.5). Aucun
// modèle Dart n'existait avant ce ticket (`RepetiteurRepository` ne
// renvoyait que des `Map<String,dynamic>` bruts pour la recherche
// apprenant, tranche initiale P5.4).

/// Une fiche `Repetiteur` (`RepetiteurSerializer` côté backend) — un
/// enseignant assigné à un cours, avec ville/tarif/disponibilité propres.
class RepetiteurFiche {
  const RepetiteurFiche({
    required this.id,
    required this.enseignantId,
    required this.nom,
    required this.coursId,
    required this.coursTitre,
    required this.matiere,
    required this.ville,
    required this.telephone,
    required this.disponible,
    required this.tarifMensuel,
    required this.noteMoyenne,
  });

  final int id;
  final int enseignantId;
  final String nom;
  final int coursId;
  final String coursTitre;
  final String matiere;
  final String ville;
  final String telephone;
  final bool disponible;
  final int tarifMensuel;
  final double noteMoyenne;

  factory RepetiteurFiche.fromJson(Map<String, dynamic> json) => RepetiteurFiche(
    id: json['id'] as int? ?? 0,
    enseignantId: json['enseignant'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    coursId: json['cours'] as int? ?? 0,
    coursTitre: json['cours_titre'] as String? ?? '',
    matiere: json['matiere'] as String? ?? '',
    ville: json['ville'] as String? ?? '',
    telephone: json['telephone'] as String? ?? '',
    disponible: json['disponible'] as bool? ?? true,
    tarifMensuel: (json['tarif_mensuel'] as num?)?.toInt() ?? 0,
    noteMoyenne: (json['note_moyenne'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Un candidat répétiteur (`RepetiteurCandidatsListView`) — un profil
/// enseignant avec son statut `is_repetiteur` et ses fiches existantes.
class RepetiteurCandidat {
  const RepetiteurCandidat({
    required this.id,
    required this.nom,
    required this.username,
    required this.isRepetiteur,
    required this.fiches,
  });

  final int id;
  final String nom;
  final String username;
  final bool isRepetiteur;
  final List<RepetiteurFiche> fiches;

  factory RepetiteurCandidat.fromJson(Map<String, dynamic> json) => RepetiteurCandidat(
    id: json['id'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    username: json['username'] as String? ?? '',
    isRepetiteur: json['is_repetiteur'] as bool? ?? false,
    fiches: (json['fiches'] as List? ?? [])
        .map((e) => RepetiteurFiche.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
