// lib/views/pages/enseignants/departement_models.dart
//
// Modèles Dart partagés entre les écrans enseignants qui gèrent un
// département (`detail_departement_page.dart`, P11.3) — réponse de
// `GET /enseignant/cadre/departement/<id>/`, distincte du modèle
// `DepartementItem` côté apprenant (`apprenants/formations_models.dart`) :
// champs orientés gestion (nb_apprenants, taux_completion par cours,
// enseignant_principal en objet) plutôt que catalogue/accès.

class CoursCadreItem {
  const CoursCadreItem({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.colorHex,
    required this.tauxCompletion,
    required this.nbApprenants,
    required this.nbLecons,
    required this.nbDevoirs,
    this.enseignantPrincipalNom,
  });

  final int id;
  final String titre;
  final String niveau;
  final String colorHex;
  final double tauxCompletion;
  final int nbApprenants;
  final int nbLecons;
  final int nbDevoirs;
  final String? enseignantPrincipalNom;

  factory CoursCadreItem.fromJson(Map<String, dynamic> json) {
    final ep = json['enseignant_principal'];
    return CoursCadreItem(
      id: json['id'] as int,
      titre: json['titre']?.toString() ?? '',
      niveau: json['niveau']?.toString() ?? '',
      colorHex: json['color_code']?.toString() ?? '#135F74',
      tauxCompletion: (json['taux_completion'] as num?)?.toDouble() ?? 0.0,
      nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
      nbLecons: (json['nb_lecons'] as num?)?.toInt() ?? 0,
      nbDevoirs: (json['nb_devoirs'] as num?)?.toInt() ?? 0,
      enseignantPrincipalNom: ep is Map ? ep['nom']?.toString() : null,
    );
  }
}

class DepartementCadreDetail {
  const DepartementCadreDetail({
    required this.id,
    required this.nom,
    required this.colorHex,
    required this.typeDepartement,
    required this.nbApprenants,
    required this.prix,
    required this.parcours,
    required this.ville,
    required this.tauxMoyen,
    required this.cours,
  });

  final int id;
  final String nom;
  final String colorHex;
  final String typeDepartement;
  final int nbApprenants;
  final int prix;
  final String parcours;
  final String ville;
  final double tauxMoyen;
  final List<CoursCadreItem> cours;

  factory DepartementCadreDetail.fromJson(Map<String, dynamic> json) {
    final coursJson = json['cours'] as List? ?? [];
    return DepartementCadreDetail(
      id: json['id'] as int,
      nom: json['nom']?.toString() ?? '',
      colorHex: json['couleur']?.toString() ?? '#135F74',
      typeDepartement: json['type_departement']?.toString() ?? 'cursus',
      nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
      prix: (json['prix'] as num?)?.toInt() ?? 0,
      parcours: json['parcours']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      tauxMoyen: (json['taux_moyen'] as num?)?.toDouble() ?? 0.0,
      cours: coursJson.map((e) => CoursCadreItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
