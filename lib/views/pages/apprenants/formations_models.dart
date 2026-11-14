// lib/views/pages/apprenants/formations_models.dart
// ════════════════════════════════════════════════════════════════
// MODÈLES POUR FORMATIONS, CONCOURS ET OLYMPIADES
// AVEC GESTION DES NIVEAUX ACCESSIBLES ET ACCÈS RESTREINT
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/auth_repository.dart';

const String kBaseUrl = ApiConstants.baseUrl;

// ================================================================
// MODÈLE COURS ITEM (pour les formations)
// ================================================================
class CoursItem {
  final int id;
  final String title;
  final String description;
  final String enseignantPrincipal;
  final String? enseignantAvatarUrl;
  final int lessons;
  final int assignments;
  final String icon;
  final String color;
  final double progression;
  final String niveau;
  final int? departementId;

  /// Accès réel au département de ce cours — `true` par défaut (aucun
  /// département cursus observé à accès restreint jusqu'ici, mais rien
  /// ne l'empêche structurellement), calculé côté backend
  /// (`ApprenantCursusAPIView`, même critère que `Departement.
  /// acces_restreint`/`apprenants_autorises`).
  final bool estAccessible;

  CoursItem({
    required this.id,
    required this.title,
    required this.description,
    required this.enseignantPrincipal,
    this.enseignantAvatarUrl,
    required this.lessons,
    required this.assignments,
    required this.icon,
    required this.color,
    required this.progression,
    required this.niveau,
    this.departementId,
    this.estAccessible = true,
  });

  factory CoursItem.fromJson(Map<String, dynamic> json) {
    return CoursItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['titre'] ?? '',
      description: json['description'] ?? json['description_brief'] ?? '',
      enseignantPrincipal: json['enseignant_principal'] ?? '---',
      enseignantAvatarUrl: json['enseignant_principal_avatar_url'] as String?,
      lessons: json['lessons'] ?? json['nb_lecons'] ?? 0,
      assignments: json['assignments'] ?? json['nb_devoirs'] ?? 0,
      icon: json['icon'] ?? json['icon_name'] ?? 'school',
      color: json['color'] ?? json['color_code'] ?? '#2884A0',
      progression: (json['progression'] as num?)?.toDouble() ?? 0.0,
      niveau: json['niveau'] ?? '',
      departementId: json['departement_id'] as int?,
      estAccessible: json['est_accessible'] as bool? ?? true,
    );
  }
}

// ================================================================
// MODÈLE DÉPARTEMENT/FORMATION
// ================================================================
class DepartementItem {
  final int id;
  final String nom;
  final String description;
  final String? imageUrl;
  final String couleur;
  final int prix;
  final int prixPresentiel;
  final int nbCours;
  final double progressionMoyenne;
  final String statut;
  final String nomConcours;
  final String organismeConcours;
  final DateTime? dateLimiteInscription;
  final DateTime? dateExamen;
  final String arreteMinisteriel;
  final String lienOfficiel;
  final String niveauxCibles;
  final List<String> niveauxAccessibles;
  final int? placesDisponibles;
  final int fraisDossier;
  final String debouches;
  final bool estFormationMetier;
  final bool estFormationClassique;
  final String dureeFormation;
  final String modeFormation;
  final String modeFormationLabel;
  final String certificatDelivre;
  final String prerequis;
  final String objectifs;
  final String domaine;
  final String ville;
  final bool estCertifiante;
  final List<CoursItem> cours;
  final Map<String, dynamic>? cadre;
  final double progression;
  final bool accesRestreint;
  final bool estAccessible;
  final String demandeStatut;
  
  DepartementItem({
    required this.id,
    required this.nom,
    required this.description,
    this.imageUrl,
    required this.couleur,
    required this.prix,
    required this.prixPresentiel,
    required this.nbCours,
    required this.progressionMoyenne,
    required this.statut,
    required this.nomConcours,
    required this.organismeConcours,
    this.dateLimiteInscription,
    this.dateExamen,
    required this.arreteMinisteriel,
    required this.lienOfficiel,
    required this.niveauxCibles,
    required this.niveauxAccessibles,
    this.placesDisponibles,
    required this.fraisDossier,
    required this.debouches,
    required this.estFormationMetier,
    required this.estFormationClassique,
    required this.dureeFormation,
    required this.modeFormation,
    required this.modeFormationLabel,
    required this.certificatDelivre,
    required this.prerequis,
    required this.objectifs,
    required this.domaine,
    required this.ville,
    required this.estCertifiante,
    required this.cours,
    this.cadre,
    required this.progression,
    required this.accesRestreint,
    required this.estAccessible,
    required this.demandeStatut,
  });
  
  factory DepartementItem.fromJson(Map<String, dynamic> json) {
    return DepartementItem(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      couleur: json['couleur'] ?? '#2884A0',
      prix: json['prix'] ?? 0,
      prixPresentiel: json['prix_presentiel'] ?? 0,
      nbCours: json['nb_cours'] ?? 0,
      progressionMoyenne: (json['progression_moyenne'] as num?)?.toDouble() ?? 0.0,
      statut: json['statut'] ?? 'NOUVEAU',
      nomConcours: json['nom_concours'] ?? '',
      organismeConcours: json['organisme_concours'] ?? '',
      dateLimiteInscription: json['date_limite_inscription'] != null 
          ? DateTime.tryParse(json['date_limite_inscription']) 
          : null,
      dateExamen: json['date_examen'] != null 
          ? DateTime.tryParse(json['date_examen']) 
          : null,
      arreteMinisteriel: json['arrete_ministeriel'] ?? '',
      lienOfficiel: json['lien_officiel'] ?? '',
      niveauxCibles: json['niveaux_cibles'] ?? '',
      niveauxAccessibles: (json['niveaux_accessibles'] as List?)?.cast<String>() ?? [],
      placesDisponibles: json['places_disponibles'],
      fraisDossier: json['frais_dossier'] ?? 0,
      debouches: json['debouches'] ?? '',
      estFormationMetier: json['est_formation_metier'] ?? false,
      estFormationClassique: json['est_formation_classique'] ?? false,
      dureeFormation: json['duree_formation'] ?? '',
      modeFormation: json['mode_formation'] ?? '',
      modeFormationLabel: _getModeFormationLabel(json['mode_formation']),
      certificatDelivre: json['certificat_delivre'] ?? '',
      prerequis: json['prerequis'] ?? '',
      objectifs: json['objectifs'] ?? '',
      domaine: json['domaine'] ?? '',
      ville: json['ville'] ?? '',
      estCertifiante: json['est_certifiante'] ?? false,
      cours: (json['cours'] as List?)?.map((c) => CoursItem.fromJson(c)).toList() ?? [],
      cadre: json['cadre'],
      progression: (json['progression'] as num?)?.toDouble() ?? 0.0,
      accesRestreint: json['acces_restreint'] ?? false,
      estAccessible: json['est_accessible'] ?? true,
      demandeStatut: json['demande_statut'] ?? '',
    );
  }
  
  static String _getModeFormationLabel(String? mode) {
    switch (mode) {
      case 'presentiel': return 'Présentiel';
      case 'distance': return 'À distance';
      case 'hybride': return 'Hybride';
      default: return '';
    }
  }
  
  bool get estAccessibleParNiveau {
    if (niveauxAccessibles.isEmpty) return true;
    return true;
  }
  
  // Propriété calculée pour savoir si l'utilisateur peut accéder
  bool get peutAcceder {
    if (!accesRestreint) return true;
    return estAccessible;
  }
  
  // Propriété calculée pour savoir si une demande est en attente
  bool get demandeEnAttente => demandeStatut == 'en_attente';
  
  // Propriété calculée pour savoir si la demande a été refusée
  bool get demandeRefusee => demandeStatut == 'refusee';
  
  // Propriété calculée pour savoir si la demande a été acceptée
  bool get demandeAcceptee => demandeStatut == 'acceptee';
  
  // Propriété calculée pour savoir si aucune demande n'a été faite
  bool get aucuneDemande => demandeStatut == '' || demandeStatut == 'non_demandee';
  
  // Message d'état d'accès
  String get messageAcces {
    if (!accesRestreint) return 'Accès libre';
    if (estAccessible) return 'Accès autorisé';
    if (demandeEnAttente) return 'Demande en attente de traitement';
    if (demandeRefusee) return 'Accès refusé. Contactez le service client.';
    return 'Demander l\'accès à cette formation';
  }
  
  // Couleur de l'état d'accès (P11.2 : tokens Yk*, plus de Colors.* en dur).
  Color get couleurAcces {
    if (!accesRestreint) return YkColors.success;
    if (estAccessible) return YkColors.success;
    if (demandeEnAttente) return YkColors.warning;
    if (demandeRefusee) return YkColors.error;
    return YkColors.neutral400;
  }
  
  // Icône de l'état d'accès
  IconData get iconeAcces {
    if (!accesRestreint) return Icons.lock_open_rounded;
    if (estAccessible) return Icons.check_circle_rounded;
    if (demandeEnAttente) return Icons.hourglass_empty_rounded;
    if (demandeRefusee) return Icons.cancel_rounded;
    return Icons.lock_outline_rounded;
  }
}

// ================================================================
// MODÈLE OLYMPIADE
// ================================================================
class OlympiadeItem {
  final int id;
  final int devoirId;
  final String titre;
  final String matiere;
  final String niveau;
  final String phase;
  final DateTime datFinInscription;
  final DateTime datDebutCompetition;
  final DateTime datFinCompetition;
  final String reglement;
  final String prixDescription;
  final bool estInscrit;
  final String statutApprenant;
  final double? note;
  final double? noteMax;
  final int? rang;
  final int dureeMinutes;
  final bool afficherClassement;
  final List<String> niveauxAccessibles;
  
  OlympiadeItem({
    required this.id,
    required this.devoirId,
    required this.titre,
    required this.matiere,
    required this.niveau,
    required this.phase,
    required this.datFinInscription,
    required this.datDebutCompetition,
    required this.datFinCompetition,
    required this.reglement,
    required this.prixDescription,
    required this.estInscrit,
    required this.statutApprenant,
    this.note,
    this.noteMax,
    this.rang,
    required this.dureeMinutes,
    required this.afficherClassement,
    required this.niveauxAccessibles,
  });
  
  factory OlympiadeItem.fromJson(Map<String, dynamic> j) {
    DateTime _d(String? s) {
      if (s == null || s.isEmpty) return DateTime.now().add(const Duration(days: 30));
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    
    final statut = j['statut'] as String? ?? 'inscription';
    final phase = switch (statut) {
      'inscription' => 'inscription',
      'en_cours' => 'competition',
      'terminee' => 'terminee',
      _ => 'attente',
    };
    
    return OlympiadeItem(
      id: j['id'] ?? 0,
      devoirId: j['devoir_id'] ?? 0,
      titre: j['titre'] ?? '',
      matiere: j['matiere'] ?? '',
      niveau: j['niveau'] ?? '',
      phase: phase,
      datFinInscription: _d(j['date_cloture_inscription']),
      datDebutCompetition: _d(j['date_debut_olympiade']),
      datFinCompetition: _d(j['date_fin_olympiade']),
      reglement: j['description'] ?? '',
      prixDescription: '${j['prix_1er'] ?? ''} / ${j['prix_2eme'] ?? ''} / ${j['prix_3eme'] ?? ''}',
      estInscrit: j['est_inscrit'] ?? false,
      statutApprenant: (j['inscription']?['statut'] as String?) ?? 'non_commence',
      note: j['inscription']?['note'] != null ? (j['inscription']['note'] as num).toDouble() : null,
      noteMax: (j['note_sur'] as num? ?? 20).toDouble(),
      rang: j['inscription']?['classement'] as int?,
      dureeMinutes: j['duree_minutes'] ?? 120,
      afficherClassement: j['statut'] == 'terminee',
      niveauxAccessibles: (j['niveaux_accessibles'] as List?)?.cast<String>() ?? [],
    );
  }
}

// ================================================================
// SERVICE POUR GÉRER LE NIVEAU DE L'APPRENANT
// ================================================================
class NiveauService {
  static const Map<String, int> niveauxOrdre = {
    '6ème': 1, '6eme': 1,
    '5ème': 2, '5eme': 2,
    '4ème': 3, '4eme': 3,
    '3ème': 4, '3eme': 4,
    'seconde': 5,
    'première': 6, 'premiere': 6,
    'terminale': 7,
    'licence 1': 8, 'licence1': 8,
    'licence 2': 9, 'licence2': 9,
    'licence 3': 10, 'licence3': 10,
    'master 1': 11, 'master1': 11,
    'master 2': 12, 'master2': 12,
    'débutant': 1, 'debutant': 1,
    'intermédiaire': 5, 'intermediaire': 5,
    'avancé': 9, 'avance': 9,
  };
  
  static String? _cachedNiveau;

  /// P11.2 : passe par `AuthRepository` (`ApiClient`) au lieu d'un `http`
  /// brut dupliquant `GET /profil/me/` — même endpoint, une seule source.
  static Future<String?> getNiveau() async {
    if (_cachedNiveau != null) return _cachedNiveau;
    try {
      final profil = await AuthRepository().getCurrentUser();
      _cachedNiveau = profil.niveau;
      return _cachedNiveau;
    } catch (e) {
      debugPrint('Erreur récupération niveau: $e');
    }
    return null;
  }
  
  static void clearCache() {
    _cachedNiveau = null;
  }
  
  static bool estAccessible(String? niveauApprenant, String niveauxCibles) {
    if (niveauxCibles.isEmpty) return true;
    if (niveauApprenant == null || niveauApprenant.isEmpty) return true;
    
    final niveauScore = niveauxOrdre[niveauApprenant.toLowerCase()] ?? 0;
    if (niveauScore == 0) return true;
    
    for (final entry in niveauxOrdre.entries) {
      if (niveauxCibles.toLowerCase().contains(entry.key.toLowerCase())) {
        if (entry.value <= niveauScore) return true;
      }
    }
    return false;
  }
  
  static bool estAccessibleParListe(String? niveauApprenant, List<String> niveauxAccessibles) {
    if (niveauxAccessibles.isEmpty) return true;
    if (niveauApprenant == null || niveauApprenant.isEmpty) return true;
    
    final niveauLower = niveauApprenant.toLowerCase();
    return niveauxAccessibles.any((n) => n.toLowerCase() == niveauLower);
  }
}