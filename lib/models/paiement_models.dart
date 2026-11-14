// lib/models/paiement_models.dart
//
// Modèles paiement manuel (P9.3) — `GET /parametres/publics/` et
// `GET /paiements/manuel/mes-demandes/` (`apps/paiement/views.py`,
// `_demande_manuelle_dict`, P9.2). Typés (contrairement à
// `WalletRepository`/l'ancien `PaiementRepository` CinetPay qui
// renvoyaient des `Map<String,dynamic>` bruts) car consommés à plusieurs
// endroits (paywall, portefeuille, suivi de demande).
//
// P9.5 : `DemandeRetrait`/`ServiceClientStatistiques` ajoutés ici (même
// domaine paiement) plutôt que dans un fichier séparé — règle 1.

/// `GET /api/abonnement/statut/?cours_id=<id>` — statut de l'abonnement
/// Premium de l'apprenant connecté DANS le département du cours donné
/// (rectification : plus un abonnement global, propre à chaque
/// département, prix fixés par l'administrateur du département).
class AbonnementInfo {
  const AbonnementInfo({
    required this.actif,
    required this.typeAbonnement,
    required this.finIso,
    required this.joursRestants,
    required this.departementId,
    required this.prixMensuel,
    required this.prixAnnuel,
    required this.disponible,
    this.libelleAbonnementCycle,
  });

  /// Nom de l'offre payée au prix [prixAnnuel] (365 jours) : « Abonnement
  /// annuel ». `null` avec un serveur pas encore à jour.
  final String? libelleAbonnementCycle;

  final bool actif;
  final String? typeAbonnement;
  final String? finIso;
  final int joursRestants;
  final int departementId;
  final int prixMensuel;
  final int prixAnnuel;

  /// `false` si l'administrateur du département n'a fixé aucun prix réel
  /// (`prixMensuel`/`prixAnnuel` tous deux à 0) — aucun abonnement
  /// possible tant que ce n'est pas le cas (aucun montant inventé).
  final bool disponible;

  factory AbonnementInfo.fromJson(Map<String, dynamic> json) => AbonnementInfo(
    actif: json['actif'] as bool? ?? false,
    typeAbonnement: json['type_abonnement'] as String?,
    finIso: json['fin'] as String?,
    joursRestants: (json['jours_restants'] as num?)?.toInt() ?? 0,
    departementId: (json['departement_id'] as num?)?.toInt() ?? 0,
    prixMensuel: (json['prix_mensuel'] as num?)?.toInt() ?? 0,
    prixAnnuel: (json['prix_annuel'] as num?)?.toInt() ?? 0,
    disponible: json['disponible'] as bool? ?? false,
    libelleAbonnementCycle: json['libelle_abonnement_cycle'] as String?,
  );
}

/// `GET /api/parametres/publics/` — non sensible, `AllowAny` côté backend.
class ParametresPublics {
  const ParametresPublics({
    required this.ussdOrangeMoney,
    required this.ussdMtnMomo,
    required this.numeroDepotOrange,
    required this.numeroDepotMtn,
    required this.nomAfficheDepot,
    required this.whatsappServiceClient,
    required this.delaiValidationPaiementMinutes,
    required this.modePaiement,
  });

  final String ussdOrangeMoney;
  final String ussdMtnMomo;
  final String numeroDepotOrange;
  final String numeroDepotMtn;
  final String nomAfficheDepot;
  final String whatsappServiceClient;
  final int delaiValidationPaiementMinutes;

  /// `manuel` | `cinetpay` | `les_deux` — gouverne si CinetPay reste
  /// proposé à côté du paiement manuel sur l'écran de paiement.
  final String modePaiement;

  bool get cinetpayDisponible => modePaiement == 'cinetpay' || modePaiement == 'les_deux';

  bool get manuelDisponible => modePaiement == 'manuel' || modePaiement == 'les_deux';

  factory ParametresPublics.fromJson(Map<String, dynamic> json) => ParametresPublics(
    ussdOrangeMoney: json['ussd_orange_money'] as String? ?? '',
    ussdMtnMomo: json['ussd_mtn_momo'] as String? ?? '',
    numeroDepotOrange: json['numero_depot_orange'] as String? ?? '',
    numeroDepotMtn: json['numero_depot_mtn'] as String? ?? '',
    nomAfficheDepot: json['nom_affiche_depot'] as String? ?? '',
    whatsappServiceClient: json['whatsapp_service_client'] as String? ?? '',
    delaiValidationPaiementMinutes: (json['delai_validation_paiement_minutes'] as num?)?.toInt() ?? 60,
    modePaiement: json['mode_paiement'] as String? ?? 'manuel',
  );
}

/// Une demande de paiement manuel — `DemandePaiementManuelle`
/// (`_demande_manuelle_dict`), commune à `MesDemandesPaiementManuelView`
/// (apprenant) et `FileAttentePaiementsServiceClientView`.
class DemandePaiementManuel {
  const DemandePaiementManuel({
    required this.id,
    required this.categorie,
    required this.montant,
    required this.montantConstate,
    required this.operateur,
    required this.idTransaction,
    required this.numeroEmetteur,
    required this.statut,
    required this.motifRefus,
    required this.dateCreation,
    required this.dateTraitement,
    this.apprenant,
  });

  final int id;
  final String categorie;
  final int montant;

  /// Constaté par le Service Client à la validation — `null` tant que la
  /// demande est `en_attente`.
  final int? montantConstate;
  final String operateur;
  final String idTransaction;
  final String numeroEmetteur;

  /// `en_attente` | `validee` | `refusee`.
  final String statut;
  final String motifRefus;
  final DateTime dateCreation;
  final DateTime? dateTraitement;

  /// P9.5 : présent uniquement dans la file d'attente Service Client
  /// (`FileAttentePaiementsServiceClientView`) — `null` dans
  /// `MesDemandesPaiementManuelView` (l'apprenant connu implicitement).
  final String? apprenant;

  factory DemandePaiementManuel.fromJson(Map<String, dynamic> json) => DemandePaiementManuel(
    id: json['id'] as int? ?? 0,
    categorie: json['categorie'] as String? ?? '',
    montant: (json['montant'] as num?)?.toInt() ?? 0,
    montantConstate: (json['montant_constate'] as num?)?.toInt(),
    operateur: json['operateur'] as String? ?? '',
    idTransaction: json['id_transaction'] as String? ?? '',
    numeroEmetteur: json['numero_emetteur'] as String? ?? '',
    statut: json['statut'] as String? ?? 'en_attente',
    motifRefus: json['motif_refus'] as String? ?? '',
    dateCreation: DateTime.tryParse(json['date_creation'] as String? ?? '') ?? DateTime.now(),
    dateTraitement: json['date_traitement'] != null
        ? DateTime.tryParse(json['date_traitement'] as String)
        : null,
    apprenant: json['apprenant'] as String?,
  );
}

/// Une demande de retrait — `DemandeRetrait` (`_demande_retrait_dict`),
/// commune à `MesDemandesRetraitView` (cadre) et
/// `FileAttenteRetraitsServiceClientView` (P9.4).
class DemandeRetrait {
  const DemandeRetrait({
    required this.id,
    required this.montantBrut,
    required this.fraisOperateur,
    required this.montantNet,
    required this.operateur,
    required this.numeroDestination,
    required this.statut,
    required this.motifRefus,
    required this.dateCreation,
    required this.dateTraitement,
    this.beneficiaire,
    this.soldeBeneficiaire,
  });

  final int id;
  final int montantBrut;
  final int fraisOperateur;
  final int montantNet;
  final String operateur;
  final String numeroDestination;

  /// `en_attente` | `validee` | `refusee`.
  final String statut;
  final String motifRefus;
  final DateTime dateCreation;
  final DateTime? dateTraitement;

  /// Présents uniquement dans la file d'attente Service Client — exigence
  /// explicite du ticket P9.5 : le solde du bénéficiaire doit être visible
  /// avant traitement.
  final String? beneficiaire;
  final int? soldeBeneficiaire;

  factory DemandeRetrait.fromJson(Map<String, dynamic> json) => DemandeRetrait(
    id: json['id'] as int? ?? 0,
    montantBrut: (json['montant_brut'] as num?)?.toInt() ?? 0,
    fraisOperateur: (json['frais_operateur'] as num?)?.toInt() ?? 0,
    montantNet: (json['montant_net'] as num?)?.toInt() ?? 0,
    operateur: json['operateur'] as String? ?? '',
    numeroDestination: json['numero_destination'] as String? ?? '',
    statut: json['statut'] as String? ?? 'en_attente',
    motifRefus: json['motif_refus'] as String? ?? '',
    dateCreation: DateTime.tryParse(json['date_creation'] as String? ?? '') ?? DateTime.now(),
    dateTraitement: json['date_traitement'] != null
        ? DateTime.tryParse(json['date_traitement'] as String)
        : null,
    beneficiaire: json['beneficiaire'] as String?,
    soldeBeneficiaire: (json['solde_beneficiaire'] as num?)?.toInt(),
  );
}

/// `GET /api/service-client/statistiques/` (P9.5) — demandes en attente,
/// délai moyen, taux de refus, paiements manuels et retraits confondus.
class ServiceClientStatistiques {
  const ServiceClientStatistiques({
    required this.demandesEnAttentePaiement,
    required this.demandesEnAttenteRetrait,
    required this.delaiMoyenMinutesPaiement,
    required this.delaiMoyenMinutesRetrait,
    required this.tauxRefusPaiement,
    required this.tauxRefusRetrait,
  });

  final int demandesEnAttentePaiement;
  final int demandesEnAttenteRetrait;

  /// `null` si aucune demande traitée encore (jamais une fausse moyenne à 0).
  final double? delaiMoyenMinutesPaiement;
  final double? delaiMoyenMinutesRetrait;
  final double? tauxRefusPaiement;
  final double? tauxRefusRetrait;

  factory ServiceClientStatistiques.fromJson(Map<String, dynamic> json) {
    final enAttente = Map<String, dynamic>.from(json['demandes_en_attente'] as Map? ?? {});
    final delai = Map<String, dynamic>.from(json['delai_moyen_minutes'] as Map? ?? {});
    final taux = Map<String, dynamic>.from(json['taux_refus_pourcent'] as Map? ?? {});
    return ServiceClientStatistiques(
      demandesEnAttentePaiement: (enAttente['paiement'] as num?)?.toInt() ?? 0,
      demandesEnAttenteRetrait: (enAttente['retrait'] as num?)?.toInt() ?? 0,
      delaiMoyenMinutesPaiement: (delai['paiement'] as num?)?.toDouble(),
      delaiMoyenMinutesRetrait: (delai['retrait'] as num?)?.toDouble(),
      tauxRefusPaiement: (taux['paiement'] as num?)?.toDouble(),
      tauxRefusRetrait: (taux['retrait'] as num?)?.toDouble(),
    );
  }
}
