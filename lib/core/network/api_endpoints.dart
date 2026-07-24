// ignore_for_file: non_constant_identifier_names
// (noms de paramètres = noms littéraux des placeholders
// OpenAPI, volontairement non renommés — voir plus bas.)
// GÉNÉRÉ — ne pas éditer à la main.
// Régénérer : dart run tool/generate_endpoints.dart
// Source : ../../yeki_backend/yeki_backend/schema_fresh.yaml
// Généré le : 2026-07-24T00:01:06.138246
//
// Chemins RELATIFS uniquement — ApiClient porte seul la
// base URL (ApiConstants.baseUrl) via Dio BaseOptions.
// Coexiste avec lib/core/constants/api_constants.dart
// (conservé pour les écrans pas encore migrés) : ce
// fichier est purement additif, consommé seulement par
// les Repositories de lib/repositories/.

class AccountsEndpoints {
  AccountsEndpoints._();

  static const String adminGeneralDashboard = '/admin-general/dashboard/';
  static String adminGeneralEnseignantsActiver(int profile_id) => '/admin-general/enseignants/$profile_id/activer/';
  static const String adminGeneralEnseignantsAttente = '/admin-general/enseignants/attente/';
  static String adminGeneralEnseignantsChangerType(int profile_id) => '/admin-general/enseignants/$profile_id/changer-type/';
  static String adminGeneralEnseignantsModifier(int profile_id) => '/admin-general/enseignants/$profile_id/modifier/';
  static const String adminGeneralEnseignantsSearch = '/admin-general/enseignants/search/';
  static const String authChangePassword = '/auth/change-password/';
  static const String authForgotPassword = '/auth/forgot-password/';
  static const String authLogin = '/auth/login/';
  static const String authLogout = '/auth/logout/';
  static const String authRegister = '/auth/register/';
  static const String authResetPassword = '/auth/reset-password/';
  static const String authVerifyOtp = '/auth/verify-otp/';
  static const String enseignantAdminDashboard = '/enseignant/admin/dashboard/';
  static const String enseignantDashboard = '/enseignant/dashboard/';
  static const String enseignants = '/enseignants/';
  static const String enseignantsCadres = '/enseignants_cadres/';
  static const String enseignantsListe = '/enseignants/liste/';
  static const String enseignantsPrincipaux = '/enseignants_principaux/';
  static const String enseignantsSecondaires = '/enseignants_secondaires/';
  static const String profilDelete = '/profil/delete/';
  static const String profilMe = '/profil/me/';
  static const String profilStats = '/profil/stats/';
  static const String profilUpdate = '/profil/update/';
}

class CoreEndpoints {
  CoreEndpoints._();

  static const String adminVersions = '/admin/versions/';
  static const String adminVersionsList = '/admin/versions/list/';
  static const String checkUpdate = '/check-update/';
  static const String historique = '/historique/';
  static const String historiqueStats = '/historique/stats/';
  static const String latestVersion = '/latest-version/';
}

class EvaluationEndpoints {
  EvaluationEndpoints._();

  static String classementDepartement(int departement_id) => '/classement/departement/$departement_id/';
  static const String classementMonScore = '/classement/mon-score/';
  static const String classementRecalculer = '/classement/recalculer/';
  static const String classementVerifierProgression = '/classement/verifier-progression/';
  static String coursDevoirs(int cours_id) => '/cours/$cours_id/devoirs/';
  static String coursDevoirsCreer(int cours_id) => '/cours/$cours_id/devoirs/creer/';
  static String coursExercices(int cours_id) => '/cours/$cours_id/exercices/';
  static String coursExercicesAjouter(int cours_id) => '/cours/$cours_id/exercices/ajouter/';
  static const String devoirs = '/devoirs/';
  static const String devoirsCadreMesDevoirs = '/devoirs/cadre/mes-devoirs/';
  static String devoirsDemarrer(int devoir_id) => '/devoirs/$devoir_id/demarrer/';
  static String devoirsDetail(int devoir_id) => '/devoirs/$devoir_id/';
  static String devoirsDupliquer(int devoir_id) => '/devoirs/$devoir_id/dupliquer/';
  static String devoirsEnonces(int devoir_id) => '/devoirs/$devoir_id/enonces/';
  static String devoirsEnonces2(int enonce_id) => '/devoirs/enonces/$enonce_id/';
  static String devoirsEnoncesQuestions(int enonce_id) => '/devoirs/enonces/$enonce_id/questions/';
  static String devoirsFocusPerdu(int devoir_id) => '/devoirs/$devoir_id/focus-perdu/';
  static const String devoirsMesSoumissions = '/devoirs/mes-soumissions/';
  static String devoirsModifier(int devoir_id) => '/devoirs/$devoir_id/modifier/';
  static String devoirsPublier(int devoir_id) => '/devoirs/$devoir_id/publier/';
  static String devoirsQuestions(int devoir_id) => '/devoirs/$devoir_id/questions/';
  static String devoirsQuestionsModifier(int question_id) => '/devoirs/questions/$question_id/modifier/';
  static String devoirsQuestionsSupprimer(int question_id) => '/devoirs/questions/$question_id/supprimer/';
  static String devoirsResultat(int devoir_id) => '/devoirs/$devoir_id/resultat/';
  static String devoirsSortir(int devoir_id) => '/devoirs/$devoir_id/sortir/';
  static String devoirsSoumettre(int devoir_id) => '/devoirs/$devoir_id/soumettre/';
  static String devoirsSoumettreFichier(int devoir_id) => '/devoirs/$devoir_id/soumettre-fichier/';
  static String devoirsSoumissions(int devoir_id) => '/devoirs/$devoir_id/soumissions/';
  static String devoirsStats(int devoir_id) => '/devoirs/$devoir_id/stats/';
  static String evaluationsExercice(int exercice_id) => '/evaluations/exercice/$exercice_id/';
  static String evaluationsExerciceHistorique(int exercice_id) => '/evaluations/exercice/$exercice_id/historique/';
  static const String evaluationsHistorique = '/evaluations/historique/';
  static String exercices(int exercice_id) => '/exercices/$exercice_id/';
  static String exercicesDemarrer(int exercice_id) => '/exercices/$exercice_id/demarrer/';
  static String exercicesEvaluer(int exercice_id) => '/exercices/$exercice_id/evaluer/';
  static String exercicesModifier(int exercice_id) => '/exercices/$exercice_id/modifier/';
  static String exercicesQuestions(int exercice_id) => '/exercices/$exercice_id/questions/';
  static String exercicesQuestionsAjouter(int exercice_id) => '/exercices/$exercice_id/questions/ajouter/';
  static String exercicesSortir(int exercice_id) => '/exercices/$exercice_id/sortir/';
  static String exercicesSupprimer(int exercice_id) => '/exercices/$exercice_id/supprimer/';
  static String modulesExercices(int module_id) => '/modules/$module_id/exercices/';
  static const String olympiades = '/olympiades/';
  static const String olympiadesCadreCreer = '/olympiades/cadre/creer/';
  static const String olympiadesCadreMesOlympiades = '/olympiades/cadre/mes-olympiades/';
  static String olympiadesCalculerClassement(int olympiade_id) => '/olympiades/$olympiade_id/calculer-classement/';
  static String olympiadesClassement(int olympiade_id) => '/olympiades/$olympiade_id/classement/';
  static String olympiadesDemarrer(int olympiade_id) => '/olympiades/$olympiade_id/demarrer/';
  static String olympiadesDetail(int olympiade_id) => '/olympiades/$olympiade_id/';
  static String olympiadesFocusPerdu(int olympiade_id) => '/olympiades/$olympiade_id/focus-perdu/';
  static String olympiadesInscrire(int olympiade_id) => '/olympiades/$olympiade_id/inscrire/';
  static String olympiadesLierDevoir(int olympiade_id) => '/olympiades/$olympiade_id/lier-devoir/';
  static String olympiadesModifier(int olympiade_id) => '/olympiades/$olympiade_id/modifier/';
  static String olympiadesMonInscription(int olympiade_id) => '/olympiades/$olympiade_id/mon-inscription/';
  static String olympiadesPayer(int olympiade_id) => '/olympiades/$olympiade_id/payer/';
  static String olympiadesPayerParticipation(int olympiade_id) => '/olympiades/$olympiade_id/payer-participation/';
  static const String olympiadesPourMoi = '/olympiades/pour-moi/';
  static String olympiadesSoumettre(int olympiade_id) => '/olympiades/$olympiade_id/soumettre/';
  static String soumissionsCorriger(int soumission_id) => '/soumissions/$soumission_id/corriger/';
  static String soumissionsDetail(int soumission_id) => '/soumissions/$soumission_id/detail/';
}

class FormationEndpoints {
  FormationEndpoints._();

  static String adminDepartementsUpdate(int id) => '/admin/departements/$id/update/';
  static const String apprenantCursus = '/apprenant/cursus/';
  static String apprenantDepartement(int id) => '/apprenant/departement/$id/';
  static String apprenantDepartementAcces(int id) => '/apprenant/departement/$id/acces/';
  static const String apprenantFormations = '/apprenant/formations/';
  static String apprenantLeconLike(int lecon_id) => '/apprenant/lecon/$lecon_id/like/';
  static const String apprenantLecturesRecentes = '/apprenant/lectures-recentes/';
  static const String apprenantMarquerLecon = '/apprenant/marquer-lecon/';
  static const String apprenantPrepaConcours = '/apprenant/prepa-concours/';
  static String coursAddEnseignant(int cours_id) => '/cours/$cours_id/add-enseignant/';
  static String coursChangerEnseignantPrincipal(int cours_id) => '/cours/$cours_id/changer-enseignant-principal/';
  static const String coursCreate = '/cours/create/';
  static String coursLecons(int cours_id) => '/cours/$cours_id/lecons/';
  static String coursListeModules(int cours_id) => '/cours/$cours_id/liste-modules/';
  static String coursModules(int cours_id) => '/cours/$cours_id/modules/';
  static const String coursPaletteCouleurs = '/cours/palette-couleurs/';
  static String coursRemoveEnseignant(int cours_id) => '/cours/$cours_id/remove-enseignant/';
  static String coursUpdate(int cours_id) => '/cours/$cours_id/update/';
  static const String departements = '/departements/';
  static String departementsApprenants(int departement_id) => '/departements/$departement_id/apprenants/';
  static String departementsChangerCadre(int departement_id) => '/departements/$departement_id/changer-cadre/';
  static String departementsCours(int departement_id) => '/departements/$departement_id/cours/';
  static const String departementsCreer = '/departements/creer/';
  static String departementsDemanderAcces(int departement_id) => '/departements/$departement_id/demander-acces/';
  static String departementsDemandes(int departement_id) => '/departements/$departement_id/demandes/';
  static String departementsDemandesTraiter(int departement_id, int demande_id) => '/departements/$departement_id/demandes/$demande_id/traiter/';
  static String departementsDetail(int id) => '/departements/$id/';
  static String departementsNiveaux(int departement_id) => '/departements/$departement_id/niveaux/';
  static const String enseignantCadreDashboard = '/enseignant/cadre/dashboard/';
  static String enseignantCadreDepartement(int departement_id) => '/enseignant/cadre/departement/$departement_id/';
  static String enseignantCadreDepartementUpdate(int departement_id) => '/enseignant/cadre/departement/$departement_id/update/';
  static const String enseignantPrincipalCours = '/enseignant_principal/cours/';
  static String leconsModifier(int lecon_id) => '/lecons/$lecon_id/modifier/';
  static String leconsSupprimer(int lecon_id) => '/lecons/$lecon_id/supprimer/';
  static String modulesModifier(int module_id) => '/modules/$module_id/modifier/';
  static String modulesSupprimer(int module_id) => '/modules/$module_id/supprimer/';
  static const String niveaux = '/niveaux/';
  static const String parcours = '/parcours/';
  static String parcoursAssignAdmin(int id) => '/parcours/$id/assign-admin/';
  static const String parcoursCreer = '/parcours/creer/';
  static String parcoursDepartements(int parcours_id) => '/parcours/$parcours_id/departements/';
  static String parcoursDetail(int parcours_id) => '/parcours/$parcours_id/';
  static const String parcoursListCreate = '/parcours/list-create/';
  static String parcoursModifier(int parcours_id) => '/parcours/$parcours_id/modifier/';
  static String parcoursNommerAdmin(int parcours_id) => '/parcours/$parcours_id/nommer-admin/';
  static const String principalApprenantsCours = '/principal/apprenants_cours/';
  static const String principalDashboardStats = '/principal/dashboard_stats/';
  static const String principalRendusDevoirs = '/principal/rendus_devoirs/';
  static const String statistiquesGlobales = '/statistiques-globales/';
  static String statsEnseignantAdmin(int id) => '/stats/enseignant-admin/$id/';
}

class ForumEndpoints {
  ForumEndpoints._();

  static String forumMessages(String room) => '/forum/$room/messages/';
  static const String forumQuestions = '/forum/questions/';
  static String forumQuestionsDetail(int id) => '/forum/questions/$id/';
  static String forumQuestionsRepondre(int id) => '/forum/questions/$id/repondre/';
  static String forumQuestionsResoudre(int id) => '/forum/questions/$id/resoudre/';
  static String forumReponsesLiker(int id) => '/forum/reponses/$id/liker/';
  static String forumReponsesSolution(int id) => '/forum/reponses/$id/solution/';
  static const String forumStats = '/forum/stats/';
}

class IaEndpoints {
  IaEndpoints._();

  static String iaCoursChat(int cours_id) => '/ia/cours/$cours_id/chat/';
  static String iaCoursHistorique(int cours_id) => '/ia/cours/$cours_id/historique/';
}

class NotificationsEndpoints {
  NotificationsEndpoints._();

  static const String notifications = '/notifications/';
  static String notificationsLire(int id) => '/notifications/$id/lire/';
  static const String notificationsNonLues = '/notifications/non-lues/';
  static const String notificationsToutLire = '/notifications/tout-lire/';
}

class PaiementEndpoints {
  PaiementEndpoints._();

  static const String abonnementStatut = '/abonnement/statut/';
  static const String paiementsCinetpayInitier = '/paiements/cinetpay/initier/';
  static const String paiementsCinetpayNotify = '/paiements/cinetpay/notify/';
  static String paiementsCinetpayVerifier(String reference) => '/paiements/cinetpay/verifier/$reference/';
  static const String paiementsHistorique = '/paiements/historique/';
  static const String paiementsManuelSoumettre = '/paiements/manuel/soumettre/';
  static const String retraitsDemander = '/retraits/demander/';
  static const String walletPayer = '/wallet/payer/';
  static const String walletRecharger = '/wallet/recharger/';
  static const String walletSolde = '/wallet/solde/';
  static const String walletVerifierIap = '/wallet/verifier-iap/';
}

class RepetiteursEndpoints {
  RepetiteursEndpoints._();

  static const String repetiteursSearch = '/repetiteurs/search/';
}

