// lib/features/admin_general/data/admin_general_models.dart
//
// Modèles administration générale (P9.6) — `GET /admin-general/dashboard/`,
// `GET /admin-general/enseignants/search/`, `GET /cours/`,
// `GET /admin/transactions/`, `GET /admin/dashboard-financier/`.

/// Référence courte à un enseignant — utilisée pour `enseignant_admin` d'un
/// parcours et `cadre` d'un département (jamais le profil complet ici).
class AdminEnseignantRef {
  const AdminEnseignantRef({required this.id, required this.nom, this.username, this.email});

  final int id;
  final String nom;
  final String? username;
  final String? email;

  factory AdminEnseignantRef.fromJson(Map<String, dynamic> json) => AdminEnseignantRef(
    id: json['id'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    username: json['username'] as String?,
    email: json['email'] as String?,
  );
}

class DashboardStats {
  const DashboardStats({
    required this.nbParcours,
    required this.nbDepartements,
    required this.nbCours,
    required this.nbApprenants,
    required this.nbEnseignants,
    required this.nbLecons,
  });

  final int nbParcours;
  final int nbDepartements;
  final int nbCours;
  final int nbApprenants;
  final int nbEnseignants;
  final int nbLecons;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    nbParcours: (json['nb_parcours'] as num?)?.toInt() ?? 0,
    nbDepartements: (json['nb_departements'] as num?)?.toInt() ?? 0,
    nbCours: (json['nb_cours'] as num?)?.toInt() ?? 0,
    nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
    nbEnseignants: (json['nb_enseignants'] as num?)?.toInt() ?? 0,
    nbLecons: (json['nb_lecons'] as num?)?.toInt() ?? 0,
  );
}

class ParcoursAdmin {
  const ParcoursAdmin({
    required this.id,
    required this.nom,
    required this.typeParcours,
    required this.nbDepartements,
    required this.nbApprenants,
    required this.nbCours,
    required this.tauxMoyen,
    this.enseignantAdmin,
  });

  final int id;
  final String nom;
  final String typeParcours;
  final int nbDepartements;
  final int nbApprenants;
  final int nbCours;
  final double tauxMoyen;
  final AdminEnseignantRef? enseignantAdmin;

  factory ParcoursAdmin.fromJson(Map<String, dynamic> json) => ParcoursAdmin(
    id: json['id'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    typeParcours: json['type_parcours'] as String? ?? 'autre',
    nbDepartements: (json['nb_departements'] as num?)?.toInt() ?? 0,
    nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
    nbCours: (json['nb_cours'] as num?)?.toInt() ?? 0,
    tauxMoyen: (json['taux_moyen'] as num?)?.toDouble() ?? 0.0,
    enseignantAdmin: json['enseignant_admin'] != null
        ? AdminEnseignantRef.fromJson(Map<String, dynamic>.from(json['enseignant_admin'] as Map))
        : null,
  );
}

class DepartementAdmin {
  const DepartementAdmin({
    required this.id,
    required this.nom,
    required this.parcoursNom,
    this.parcoursId,
    required this.nbCours,
    required this.nbApprenants,
    required this.tauxMoyen,
    this.cadre,
  });

  final int id;
  final String nom;
  final String parcoursNom;
  final int? parcoursId;
  final int nbCours;
  final int nbApprenants;
  final double tauxMoyen;
  final AdminEnseignantRef? cadre;

  factory DepartementAdmin.fromJson(Map<String, dynamic> json) => DepartementAdmin(
    id: json['id'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    parcoursNom: json['parcours'] as String? ?? '',
    parcoursId: json['parcours_id'] as int?,
    nbCours: (json['nb_cours'] as num?)?.toInt() ?? 0,
    nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
    tauxMoyen: (json['taux_moyen'] as num?)?.toDouble() ?? 0.0,
    cadre: json['cadre'] != null
        ? AdminEnseignantRef.fromJson(Map<String, dynamic>.from(json['cadre'] as Map))
        : null,
  );
}

class TopEnseignant {
  const TopEnseignant({required this.id, required this.nom, required this.role, required this.score});

  final int id;
  final String nom;
  final String role;
  final double score;

  factory TopEnseignant.fromJson(Map<String, dynamic> json) => TopEnseignant(
    id: json['id'] as int? ?? 0,
    nom: json['nom'] as String? ?? '',
    role: json['role'] as String? ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
  );
}

class EnseignantAdmin {
  const EnseignantAdmin({
    required this.id,
    required this.username,
    required this.email,
    required this.nom,
    required this.userType,
    required this.isActive,
    required this.dateJoined,
    required this.bio,
    required this.phone,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String email;
  final String nom;
  final String userType;
  final bool isActive;
  final DateTime? dateJoined;
  final String bio;
  final String phone;
  final String? avatarUrl;

  factory EnseignantAdmin.fromJson(Map<String, dynamic> json) => EnseignantAdmin(
    id: json['id'] as int? ?? 0,
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    nom: json['nom'] as String? ?? '',
    userType: json['user_type'] as String? ?? 'enseignant',
    isActive: json['is_active'] as bool? ?? false,
    dateJoined: json['date_joined'] != null ? DateTime.tryParse(json['date_joined'] as String) : null,
    bio: json['bio'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    avatarUrl: json['avatar'] as String?,
  );
}

class AdminGeneralDashboard {
  const AdminGeneralDashboard({
    required this.stats,
    required this.parcours,
    required this.departements,
    required this.topEnseignants,
    required this.enseignants,
  });

  final DashboardStats stats;
  final List<ParcoursAdmin> parcours;
  final List<DepartementAdmin> departements;
  final List<TopEnseignant> topEnseignants;
  final List<EnseignantAdmin> enseignants;

  factory AdminGeneralDashboard.fromJson(Map<String, dynamic> json) => AdminGeneralDashboard(
    stats: DashboardStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map? ?? {})),
    parcours: (json['parcours'] as List? ?? [])
        .map((e) => ParcoursAdmin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    departements: (json['departements'] as List? ?? [])
        .map((e) => DepartementAdmin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    topEnseignants: (json['top_enseignants'] as List? ?? [])
        .map((e) => TopEnseignant.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    enseignants: (json['enseignants'] as List? ?? [])
        .map((e) => EnseignantAdmin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

/// Une ligne de `GET /cours/` (P9.6 : route câblée pour la première fois,
/// voir `apps/formation/views/cours.py::liste_cours`) — pas de nom de
/// département disponible depuis cet endpoint (seulement son id).
class CoursAdmin {
  const CoursAdmin({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.colorCode,
    required this.nbApprenants,
    required this.nbLecons,
    required this.nbDevoirs,
  });

  final int id;
  final String titre;
  final String niveau;
  final String colorCode;
  final int nbApprenants;
  final int nbLecons;
  final int nbDevoirs;

  factory CoursAdmin.fromJson(Map<String, dynamic> json) => CoursAdmin(
    id: json['id'] as int? ?? 0,
    titre: json['titre'] as String? ?? 'Sans titre',
    niveau: json['niveau'] as String? ?? '',
    colorCode: json['color_code'] as String? ?? '#008080',
    nbApprenants: (json['nb_apprenants'] as num?)?.toInt() ?? 0,
    nbLecons: (json['nb_lecons'] as num?)?.toInt() ?? 0,
    nbDevoirs: (json['nb_devoirs'] as num?)?.toInt() ?? 0,
  );
}

/// Une ligne de `GET /admin/transactions/` — voir
/// `apps/paiement/views.py::_transaction_dict`. `partTiersBeneficiaire`
/// est 0 (jamais `null`) pour recharge/abonnement/presentiel, catégories
/// sans répartition tiers par construction.
class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.date,
    required this.apprenant,
    required this.categorie,
    this.departement,
    required this.montantBrut,
    required this.partYeki,
    required this.partTiersBeneficiaire,
    this.beneficiaire,
    required this.operateur,
    required this.statut,
    this.decideur,
  });

  final int id;
  final DateTime date;
  final String apprenant;
  final String categorie;
  final String? departement;
  final int montantBrut;
  final int partYeki;
  final int partTiersBeneficiaire;
  final String? beneficiaire;
  final String operateur;
  final String statut;
  final String? decideur;

  factory AdminTransaction.fromJson(Map<String, dynamic> json) => AdminTransaction(
    id: json['id'] as int? ?? 0,
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    apprenant: json['apprenant'] as String? ?? '',
    categorie: json['categorie'] as String? ?? '',
    departement: json['departement'] as String?,
    montantBrut: (json['montant_brut'] as num?)?.toInt() ?? 0,
    partYeki: (json['part_yeki'] as num?)?.toInt() ?? 0,
    partTiersBeneficiaire: (json['part_tiers_beneficiaire'] as num?)?.toInt() ?? 0,
    beneficiaire: json['beneficiaire'] as String?,
    operateur: json['operateur'] as String? ?? '',
    statut: json['statut'] as String? ?? '',
    decideur: json['decideur'] as String?,
  );
}

class VentilationDepartement {
  const VentilationDepartement({required this.departementId, required this.departementNom, required this.total});

  final int departementId;
  final String departementNom;
  final int total;

  factory VentilationDepartement.fromJson(Map<String, dynamic> json) => VentilationDepartement(
    departementId: json['departement_id'] as int? ?? 0,
    departementNom: json['departement__nom'] as String? ?? '',
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

/// `GET /admin/dashboard-financier/` — voir
/// `apps/paiement/views.py::AdminDashboardFinancierView`. Point comptable
/// central (ticket P9.6) : [totalDuAuxCadres] est une DETTE de Yéki, JAMAIS
/// fondue dans [totalEncaisse] — les deux restent des champs distincts ici
/// comme côté backend, à ne jamais additionner à l'affichage.
class AdminDashboardFinancier {
  const AdminDashboardFinancier({
    required this.totalEncaisse,
    required this.ventilationCategorie,
    required this.ventilationDepartement,
    required this.soldeCompteIa,
    required this.soldeGeneralYekiCalcule,
    required this.totalDuAuxCadres,
    required this.demandesEnAttentePaiement,
    required this.demandesEnAttenteRetrait,
    this.delaiMoyenMinutesPaiement,
    this.delaiMoyenMinutesRetrait,
  });

  final int totalEncaisse;
  final Map<String, int> ventilationCategorie;
  final List<VentilationDepartement> ventilationDepartement;
  final int soldeCompteIa;
  final int soldeGeneralYekiCalcule;
  final int totalDuAuxCadres;
  final int demandesEnAttentePaiement;
  final int demandesEnAttenteRetrait;
  final double? delaiMoyenMinutesPaiement;
  final double? delaiMoyenMinutesRetrait;

  factory AdminDashboardFinancier.fromJson(Map<String, dynamic> json) {
    final ventilationCategorie = Map<String, dynamic>.from(json['ventilation_categorie'] as Map? ?? {});
    final demandesEnAttente = Map<String, dynamic>.from(json['demandes_en_attente'] as Map? ?? {});
    final delaiMoyen = Map<String, dynamic>.from(json['delai_moyen_minutes'] as Map? ?? {});
    return AdminDashboardFinancier(
      totalEncaisse: (json['total_encaisse'] as num?)?.toInt() ?? 0,
      ventilationCategorie: ventilationCategorie.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      ventilationDepartement: (json['ventilation_departement'] as List? ?? [])
          .map((e) => VentilationDepartement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      soldeCompteIa: (json['solde_compte_ia'] as num?)?.toInt() ?? 0,
      soldeGeneralYekiCalcule: (json['solde_general_yeki_calcule'] as num?)?.toInt() ?? 0,
      totalDuAuxCadres: (json['total_du_aux_cadres'] as num?)?.toInt() ?? 0,
      demandesEnAttentePaiement: (demandesEnAttente['paiement'] as num?)?.toInt() ?? 0,
      demandesEnAttenteRetrait: (demandesEnAttente['retrait'] as num?)?.toInt() ?? 0,
      delaiMoyenMinutesPaiement: (delaiMoyen['paiement'] as num?)?.toDouble(),
      delaiMoyenMinutesRetrait: (delaiMoyen['retrait'] as num?)?.toDouble(),
    );
  }
}
