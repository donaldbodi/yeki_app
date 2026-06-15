// lib/core/constants/api_constants.dart
// ═══════════════════════════════════════════════════════════════════════════
//  CONSTANTES API CENTRALISÉES (CORRIGÉES)
//  À UTILISER DANS TOUTES LES REQUÊTES HTTP
// ═══════════════════════════════════════════════════════════════════════════

class ApiConstants {
  // URL de base
  static const String baseUrl = 'https://yeki.pythonanywhere.com/api';
  
  // Endpoints Auth (pas de paramètres)
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String forgotPassword = '$baseUrl/auth/forgot-password/';
  static const String verifyOtp = '$baseUrl/auth/verify-otp/';
  static const String resetPassword = '$baseUrl/auth/reset-password/';
  static const String changePassword = '$baseUrl/auth/change-password/';
  
  // Endpoints Profil
  static const String profilMe = '$baseUrl/profil/me/';
  static const String profilUpdate = '$baseUrl/profil/update/';
  static const String profilDelete = '$baseUrl/profil/delete/';
  static const String profilStats = '$baseUrl/profil/stats/';
  
  // Endpoints Apprenant
  static const String cursus = '$baseUrl/apprenant/cursus/';
  static const String lecturesRecentes = '$baseUrl/apprenant/lectures-recentes/';
  static const String marquerLecon = '$baseUrl/apprenant/marquer-lecon/';
  static const String prepaConcours = '$baseUrl/apprenant/prepa-concours/';
  static const String formations = '$baseUrl/apprenant/formations/';
  
  // Endpoints Cours (avec paramètres - utiliser des méthodes statiques)
  static String coursModules(int id) => '$baseUrl/cours/$id/liste-modules/';
  static String coursDevoirs(int id) => '$baseUrl/cours/$id/devoirs/';
  static String coursExercices(int id) => '$baseUrl/cours/$id/exercices/';
  static String coursLecons(int id) => '$baseUrl/cours/$id/lecons/';
  static String moduleCreate(int id) => '$baseUrl/cours/$id/modules/';
  
  // Endpoints Leçons
  static String leconModifier(int id) => '$baseUrl/lecons/$id/modifier/';
  static String leconSupprimer(int id) => '$baseUrl/lecons/$id/supprimer/';
  static String leconLike(int id) => '$baseUrl/apprenant/lecon/$id/like/';
  
  // Endpoints Exercices
  static String exerciceDetail(int id) => '$baseUrl/exercices/$id/';
  static String exerciceDemarrer(int id) => '$baseUrl/exercices/$id/demarrer/';
  static String exerciceEvaluer(int id) => '$baseUrl/exercices/$id/evaluer/';
  static String resultatExercice(int id) => '$baseUrl/evaluations/exercice/$id/';
  static const String historiqueEvaluations = '$baseUrl/evaluations/historique/';
  
  // Endpoints Devoirs
  static const String devoirs = '$baseUrl/devoirs/';
  static String devoirDetail(int id) => '$baseUrl/devoirs/$id/';
  static String devoirDemarrer(int id) => '$baseUrl/devoirs/$id/demarrer/';
  static String devoirSoumettre(int id) => '$baseUrl/devoirs/$id/soumettre/';
  static String devoirFocusPerdu(int id) => '$baseUrl/devoirs/$id/focus-perdu/';
  static String devoirResultat(int id) => '$baseUrl/devoirs/$id/resultat/';
  
  // Endpoints Olympiades
  static const String olympiades = '$baseUrl/olympiades/';
  static const String olympiadesPourMoi = '$baseUrl/olympiades/pour-moi/';
  static String olympiadeDetail(int id) => '$baseUrl/olympiades/$id/';
  static String olympiadeInscrire(int id) => '$baseUrl/olympiades/$id/inscrire/';
  static String olympiadeDemarrer(int id) => '$baseUrl/olympiades/$id/demarrer/';
  static String olympiadeSoumettre(int id) => '$baseUrl/olympiades/$id/soumettre/';
  static String olympiadeFocusPerdu(int id) => '$baseUrl/olympiades/$id/focus-perdu/';
  static String olympiadeClassement(int id) => '$baseUrl/olympiades/$id/classement/';
  
  // Endpoints Forum
  static const String forumQuestions = '$baseUrl/forum/questions/';
  static String forumQuestionDetail(int id) => '$baseUrl/forum/questions/$id/';
  static String forumQuestionRepondre(int id) => '$baseUrl/forum/questions/$id/repondre/';
  static String forumQuestionResoudre(int id) => '$baseUrl/forum/questions/$id/resoudre/';
  static String forumReponseLiker(int id) => '$baseUrl/forum/reponses/$id/liker/';
  static String forumReponseSolution(int id) => '$baseUrl/forum/reponses/$id/solution/';
  static const String forumStats = '$baseUrl/forum/stats/';
  
  // Endpoints Enseignants
  static const String enseignantDashboard = '$baseUrl/enseignant/dashboard/';
  static const String enseignantAdminDashboard = '$baseUrl/enseignant/admin/dashboard/';
  static const String enseignantCadreDashboard = '$baseUrl/enseignant/cadre/dashboard/';
  static const String enseignantCadreCours = '$baseUrl/enseignant/cadre/cours/';
  static const String enseignantPrincipalCours = '$baseUrl/enseignant_principal/cours/';
  static const String enseignantCours = '$baseUrl/enseignant/cours/';
  static const String listeEnseignants = '$baseUrl/enseignants/liste/';
  static String enseignantCadreDepartement(int id) => '$baseUrl/enseignant/cadre/departement/$id/';
  static String departementCours(int id) => '$baseUrl/departements/$id/cours/';
  static String changerEnseignantPrincipal(int id) => '$baseUrl/cours/$id/changer-enseignant-principal/';
  
  // Endpoints Yeki IA
  static String iaChat(int id) => '$baseUrl/ia/cours/$id/chat/';
  static String iaHistorique(int id) => '$baseUrl/ia/cours/$id/historique/';
  
  // Endpoints Wallet
  static const String walletSolde = '$baseUrl/wallet/solde/';
  static const String walletRecharger = '$baseUrl/wallet/recharger/';
  static const String walletPayer = '$baseUrl/wallet/payer/';
  
  // Endpoints Paiement
  static const String paiementCinetpayInitier = '$baseUrl/paiements/cinetpay/initier/';
  static const String paiementHistorique = '$baseUrl/paiements/historique/';
  
  // Endpoints Classement
  static String classementDepartement(int id) => '$baseUrl/classement/departement/$id/';
  static const String monScore = '$baseUrl/classement/mon-score/';
  
  // Endpoints Admin
  static const String adminGeneralDashboard = '$baseUrl/admin-general/dashboard/';
  static const String parcoursCreer = '$baseUrl/parcours/creer/';
  static const String departementsCreer = '$baseUrl/departements/creer/';
  static const String olympiadesCadreCreer = '$baseUrl/olympiades/cadre/creer/';
  
  // Endpoints Divers
  static const String historique = '$baseUrl/historique/';
  static const String historiqueStats = '$baseUrl/historique/stats/';
  static const String latestVersion = '$baseUrl/latest-version/';
  static const String niveaux = '$baseUrl/niveaux/';
}

// Headers pour les requêtes HTTP
class ApiHeaders {
  static Map<String, String> auth(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };
  
  static Map<String, String> authMultipart(String? token) => {
    if (token != null) 'Authorization': 'Token $token',
  };
}