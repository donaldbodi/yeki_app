// lib/core/constants/api_constants.dart
// ═══════════════════════════════════════════════════════════════════════════
//  CONSTANTES API CENTRALISÉES (VERSION COMPLÈTE)
// ═══════════════════════════════════════════════════════════════════════════

class ApiConstants {
  // URL de base
  static const String baseUrl = 'https://yeki.pythonanywhere.com/api';
  
  // ── Endpoints Auth ────────────────────────────────────────────────────────
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String changePassword = '$baseUrl/auth/change-password/';
  
  // ── Endpoints Profil ─────────────────────────────────────────────────────
  static const String profilMe = '$baseUrl/profil/me/';
  static const String profilUpdate = '$baseUrl/profil/update/';
  static const String profilDelete = '$baseUrl/profil/delete/';
  static const String profilStats = '$baseUrl/profil/stats/';
  
  // ── Endpoints Apprenant ─────────────────────────────────────────────────
  static const String cursus = '$baseUrl/apprenant/cursus/';
  static const String lecturesRecentes = '$baseUrl/apprenant/lectures-recentes/';
  static const String marquerLecon = '$baseUrl/apprenant/marquer-lecon/';
  static const String prepaConcours = '$baseUrl/apprenant/prepa-concours/';
  static const String formations = '$baseUrl/apprenant/formations/';
  static const String leconLike = '$baseUrl/apprenant/lecon/like/';
  
  // ── Endpoints Cours (avec paramètres) ──────────────────────────────────
  static String coursModules(int id) => '$baseUrl/cours/$id/liste-modules/';
  static String coursDevoirs(int id) => '$baseUrl/cours/$id/devoirs/';
  static String coursExercices(int id) => '$baseUrl/cours/$id/exercices/';
  static String coursLecons(int id) => '$baseUrl/cours/$id/lecons/';
  static String moduleCreate(int id) => '$baseUrl/cours/$id/modules/';
  static String coursUpdate(int id) => '$baseUrl/cours/$id/update/';
  static String coursChangerPrincipal(int id) => '$baseUrl/cours/$id/changer-enseignant-principal/';
  static String coursAddEnseignant(int id) => '$baseUrl/cours/$id/add-enseignant/';
  static String coursRemoveEnseignant(int id) => '$baseUrl/cours/$id/remove-enseignant/';
  
  // ── Endpoints Leçons ────────────────────────────────────────────────────
  static String leconModifier(int id) => '$baseUrl/lecons/$id/modifier/';
  static String leconSupprimer(int id) => '$baseUrl/lecons/$id/supprimer/';
  static String leconLikeId(int id) => '$baseUrl/apprenant/lecon/$id/like/';
  
  // ── Endpoints Exercices ──────────────────────────────────────────────────
  static String exerciceDetail(int id) => '$baseUrl/exercices/$id/';
  static String exerciceDemarrer(int id) => '$baseUrl/exercices/$id/demarrer/';
  static String exerciceEvaluer(int id) => '$baseUrl/exercices/$id/evaluer/';
  static String exerciceSortir(int id) => '$baseUrl/exercices/$id/sortir/';
  static String resultatExercice(int id) => '$baseUrl/evaluations/exercice/$id/';
  static String historiqueTentativesExercice(int id) => '$baseUrl/evaluations/exercice/$id/historique/';
  static const String historiqueEvaluations = '$baseUrl/evaluations/historique/';
  static String exerciceModifier(int id) => '$baseUrl/exercices/$id/modifier/';
  static String exerciceSupprimer(int id) => '$baseUrl/exercices/$id/supprimer/';
  static String exerciceAjouter(int id) => '$baseUrl/cours/$id/exercices/ajouter/';
  static String exerciceQuestions(int id) => '$baseUrl/exercices/$id/questions/';
  static String exerciceAjouterQuestion(int id) => '$baseUrl/exercices/$id/questions/ajouter/';
  
  // ── Endpoints Devoirs ─────────────────────────────────────────────────────
  static const String devoirs = '$baseUrl/devoirs/';
  static String devoirDetail(int id) => '$baseUrl/devoirs/$id/';
  static String devoirDemarrer(int id) => '$baseUrl/devoirs/$id/demarrer/';
  static String devoirSoumettre(int id) => '$baseUrl/devoirs/$id/soumettre/';
  static String devoirFocusPerdu(int id) => '$baseUrl/devoirs/$id/focus-perdu/';
  static String devoirResultat(int id) => '$baseUrl/devoirs/$id/resultat/';
  static String devoirCreer(int id) => '$baseUrl/cours/$id/devoirs/creer/';
  static String devoirModifier(int id) => '$baseUrl/devoirs/$id/modifier/';
  static String devoirPublier(int id) => '$baseUrl/devoirs/$id/publier/';
  static String devoirDupliquer(int id) => '$baseUrl/devoirs/$id/dupliquer/';
  static String devoirSortir(int id) => '$baseUrl/devoirs/$id/sortir/';
  static String devoirQuestions(int id) => '$baseUrl/devoirs/$id/questions/';
  static String devoirAjouterQuestion(int id) => '$baseUrl/devoirs/$id/questions/ajouter/';
  static String devoirModifierQuestion(int id) => '$baseUrl/devoirs/questions/$id/modifier/';
  static String devoirSupprimerQuestion(int id) => '$baseUrl/devoirs/questions/$id/supprimer/';
  static String devoirSoumissions(int id) => '$baseUrl/devoirs/$id/soumissions/';
  static String devoirStats(int id) => '$baseUrl/devoirs/$id/stats/';
  static String devoirSoumettreFichier(int id) => '$baseUrl/devoirs/$id/soumettre-fichier/';
  static const String mesSoumissions = '$baseUrl/devoirs/mes-soumissions/';
  
  // ── Endpoints Soumissions ─────────────────────────────────────────────────
  static String soumissionDetail(int id) => '$baseUrl/soumissions/$id/detail/';
  static String soumissionCorriger(int id) => '$baseUrl/soumissions/$id/corriger/';
  
  // ── Endpoints Olympiades ──────────────────────────────────────────────────
  static const String olympiades = '$baseUrl/olympiades/';
  static const String olympiadesPourMoi = '$baseUrl/olympiades/pour-moi/';
  static String olympiadeDetail(int id) => '$baseUrl/olympiades/$id/';
  static String olympiadeInscrire(int id) => '$baseUrl/olympiades/$id/inscrire/';
  static String olympiadeDemarrer(int id) => '$baseUrl/olympiades/$id/demarrer/';
  static String olympiadeSoumettre(int id) => '$baseUrl/olympiades/$id/soumettre/';
  static String olympiadeFocusPerdu(int id) => '$baseUrl/olympiades/$id/focus-perdu/';
  static String olympiadeClassement(int id) => '$baseUrl/olympiades/$id/classement/';
  static const String olympiadesCadreCreer = '$baseUrl/olympiades/cadre/creer/';
  static const String mesOlympiadesCadre = '$baseUrl/olympiades/cadre/mes-olympiades/';
  static String olympiadeLierDevoir(int id) => '$baseUrl/olympiades/$id/lier-devoir/';
  static String olympiadeModifier(int id) => '$baseUrl/olympiades/$id/modifier/';
  static String olympiadePayer(int id) => '$baseUrl/olympiades/$id/payer/';
  static String olympiadePayerParticipation(int id) => '$baseUrl/olympiades/$id/payer-participation/';
  static String olympiadeCalculerClassement(int id) => '$baseUrl/olympiades/$id/calculer-classement/';
  static String olympiadeMonInscription(int id) => '$baseUrl/olympiades/$id/mon-inscription/';
  
  // ── Endpoints Forum ────────────────────────────────────────────────────────
  static const String forumQuestions = '$baseUrl/forum/questions/';
  static String forumQuestionDetail(int id) => '$baseUrl/forum/questions/$id/';
  static String forumQuestionRepondre(int id) => '$baseUrl/forum/questions/$id/repondre/';
  static String forumQuestionResoudre(int id) => '$baseUrl/forum/questions/$id/resoudre/';
  static String forumReponseLiker(int id) => '$baseUrl/forum/reponses/$id/liker/';
  static String forumReponseSolution(int id) => '$baseUrl/forum/reponses/$id/solution/';
  static const String forumStats = '$baseUrl/forum/stats/';

  // Sondage incrémental (repli du forum temps réel — voir docs/FORUM_TEMPS_REEL.md).
  // `room` : id de cours (String) ou 'global'. `PythonAnywhere ne supporte pas
  // les WebSockets : ce drapeau documente qu'aucune connexion temps réel ne
  // doit être tentée tant qu'il reste à false — voir le fichier ci-dessus.
  static const bool forumRealtimeEnabled = false;
  static String forumMessages(String room) => '$baseUrl/forum/$room/messages/';

  // ── Endpoints Enseignants ─────────────────────────────────────────────────
  static const String enseignantDashboard = '$baseUrl/enseignant/dashboard/';
  static const String enseignantAdminDashboard = '$baseUrl/enseignant/admin/dashboard/';
  static const String enseignantCadreDashboard = '$baseUrl/enseignant/cadre/dashboard/';
  static const String enseignantCadreCours = '$baseUrl/enseignant/cadre/cours/';
  static const String enseignantPrincipalCours = '$baseUrl/enseignant_principal/cours/';
  static const String enseignantCours = '$baseUrl/enseignant/cours/';
  static const String listeEnseignants = '$baseUrl/enseignants/liste/';
  static const String listeEnseignantsParRole = '$baseUrl/enseignants/liste/';
  static String enseignantCadreDepartement(int id) => '$baseUrl/enseignant/cadre/departement/$id/';
  static String enseignantCadreDepartementUpdate(int id) => '$baseUrl/enseignant/cadre/departement/$id/update/';
  static String departementCours(int id) => '$baseUrl/departements/$id/cours/';
  
  // ── Endpoints Admin General ──────────────────────────────────────────────
  static const String adminGeneralDashboard = '$baseUrl/admin-general/dashboard/';
  static const String adminGeneralEnseignants = '$baseUrl/admin-general/enseignants/';
  static const String adminGeneralEnseignantsAttente = '$baseUrl/admin-general/enseignants/attente/';
  static String adminGeneralActiverEnseignant(int id) => '$baseUrl/admin-general/enseignants/$id/activer/';
  static String adminGeneralDesactiverEnseignant(int id) => '$baseUrl/admin-general/enseignants/$id/desactiver/';
  static String adminGeneralModifierEnseignant(int id) => '$baseUrl/admin-general/enseignants/$id/modifier/';
  static String adminGeneralChangerType(int id) => '$baseUrl/admin-general/enseignants/$id/changer-type/';
  static const String adminGeneralSearchEnseignants = '$baseUrl/admin-general/enseignants/search/';
  
  // ── Endpoints Parcours ─────────────────────────────────────────────────────
  static const String parcours = '$baseUrl/parcours/';
  static String parcoursDetail(int id) => '$baseUrl/parcours/$id/';
  static const String parcoursCreer = '$baseUrl/parcours/creer/';
  static String parcoursModifier(int id) => '$baseUrl/parcours/$id/modifier/';
  static String parcoursNommerAdmin(int id) => '$baseUrl/parcours/$id/nommer-admin/';
  static String parcoursDepartements(int id) => '$baseUrl/parcours/$id/departements/';
  
  // ── Endpoints Départements ───────────────────────────────────────────────
  static const String departements = '$baseUrl/departements/';
  static String departementDetail(int id) => '$baseUrl/departements/$id/';
  static const String departementsCreer = '$baseUrl/departements/creer/';
  static String departementModifier(int id) => '$baseUrl/departements/$id/update/';
  static String departementChangerCadre(int id) => '$baseUrl/departements/$id/changer-cadre/';
  static String departementDemanderAcces(int id) => '$baseUrl/departements/$id/demander-acces/';
  static String departementDemandes(int id) => '$baseUrl/departements/$id/demandes/';
  static String departementTraiterDemande(int id, int demandeId) => '$baseUrl/departements/$id/demandes/$demandeId/traiter/';
  static String departementVerifierAcces(int id) => '$baseUrl/apprenant/departement/$id/acces/';
  static String departementNiveaux(int id) => '$baseUrl/departements/$id/niveaux/';
  static String departementApprenants(int id) => '$baseUrl/departements/$id/apprenants/';
  
  // ── Endpoints Modules ──────────────────────────────────────────────────────
  static String moduleModifier(int id) => '$baseUrl/modules/$id/modifier/';
  static String moduleSupprimer(int id) => '$baseUrl/modules/$id/supprimer/';
  static String moduleExercices(int id) => '$baseUrl/modules/$id/exercices/';
  
  // ── Endpoints Yeki IA ──────────────────────────────────────────────────────
  static String iaChat(int id) => '$baseUrl/ia/cours/$id/chat/';
  static String iaHistorique(int id) => '$baseUrl/ia/cours/$id/historique/';
  
  // ── Endpoints Wallet ──────────────────────────────────────────────────────
  static const String walletSolde = '$baseUrl/wallet/solde/';
  static const String walletRecharger = '$baseUrl/wallet/recharger/';
  static const String walletPayer = '$baseUrl/wallet/payer/';
  static const String walletVerifierIAP = '$baseUrl/wallet/verifier-iap/';
  
  // ── Endpoints Paiement ─────────────────────────────────────────────────────
  static const String paiementCinetpayInitier = '$baseUrl/paiements/cinetpay/initier/';
  static const String paiementCinetpayNotify = '$baseUrl/paiements/cinetpay/notify/';
  static String paiementCinetpayVerifier(String ref) => '$baseUrl/paiements/cinetpay/verifier/$ref/';
  static const String paiementHistorique = '$baseUrl/paiements/historique/';
  static const String abonnementStatut = '$baseUrl/abonnement/statut/';
  
  // ── Endpoints Classement ──────────────────────────────────────────────────
  static String classementDepartement(int id) => '$baseUrl/classement/departement/$id/';
  static const String monScore = '$baseUrl/classement/mon-score/';
  static const String recalculerClassement = '$baseUrl/classement/recalculer/';
  static const String verifierProgressionRang = '$baseUrl/classement/verifier-progression/';
  
  // ── Endpoints Historique ───────────────────────────────────────────────────
  static const String historique = '$baseUrl/historique/';
  static const String historiqueStats = '$baseUrl/historique/stats/';
  
  // ── Endpoints Divers ──────────────────────────────────────────────────────
  static const String latestVersion = '$baseUrl/latest-version/';
  static const String niveaux = '$baseUrl/niveaux/';
  static const String statistiquesGlobales = '$baseUrl/statistiques-globales/';
  static const String repetitionsSearch = '$baseUrl/repetiteurs/search/';
  
  // ── Endpoints Enseignant Principal ────────────────────────────────────────
  static const String principalDashboard = '$baseUrl/principal/dashboard_stats/';
  static const String principalApprenants = '$baseUrl/principal/apprenants_cours/';
  static const String principalRendus = '$baseUrl/principal/rendus_devoirs/';
  
  // ── Endpoints Cadre - Devoirs ─────────────────────────────────────────────
  static const String cadreDevoirs = '$baseUrl/devoirs/cadre/mes-devoirs/';
  
  // ── Endpoints Version ──────────────────────────────────────────────────────
  static const String checkUpdate = '$baseUrl/check-update/';
  static const String adminVersions = '$baseUrl/admin/versions/';
  static const String adminVersionsList = '$baseUrl/admin/versions/list/';
  // Nouveau mécanisme de vérification de version (P5.1bis) — endpoint et
  // écran de blocage réels arrivent en P12.1, voir UpdateService
  // .checkMandatoryVersion(). N'existe pas encore côté Django : appel
  // posé maintenant, câblé plus tard.
  static const String appVersion = '$baseUrl/app/version/';
  
  // ── Endpoints Notifications ──────────────────────────────────────────────
  static const String notifications = '$baseUrl/notifications/';
  static String notificationLire(int id) => '$baseUrl/notifications/$id/lire/';
  static const String notificationsToutLire = '$baseUrl/notifications/tout-lire/';
  static const String notificationsNonLues = '$baseUrl/notifications/non-lues/';
}

// ── Headers pour les requêtes HTTP ──────────────────────────────────────────
class ApiHeaders {
  static Map<String, String> auth(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };
  
  static Map<String, String> authMultipart(String? token) => {
    if (token != null) 'Authorization': 'Token $token',
  };
}