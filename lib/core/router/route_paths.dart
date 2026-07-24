/// Gabarits de chemin — consommés uniquement par `app_router.dart`.
/// Aucun écran ne doit importer ce fichier : ils naviguent par NOM
/// (`route_names.dart`), jamais par chemin littéral, pour que ces
/// gabarits puissent changer sans toucher aux ~81 sites d'appel.
abstract final class AppPath {
  // ── Racine / auth ──────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String forbidden = '/403';
  static const String notFound = '/404';
  static const String designSystem = '/design-system';

  // ── Apprenant : onglets du shell (chemins complets) ─────────────
  static const String dashboardCursus = '/dashboard/cursus';
  static const String dashboardConcours = '/dashboard/concours';
  static const String dashboardFormations = '/dashboard/formations';
  static const String dashboardOlympiades = '/dashboard/olympiades';
  static const String dashboardDevoirs = '/dashboard/devoirs';

  // ── Apprenant : plein écran (chemins complets pour namedLocation) ──
  static const String repetiteurs = '/repetiteurs';
  static const String settings = '/settings';
  static const String coursDetail = '/cours/:coursId';
  static const String leconDetail = '/cours/:coursId/lecons/:leconId';
  static const String leconLecture = '/cours/:coursId/lecons/:leconId/lire';
  static const String exercicePasser = '/exercices/:exerciceId/passer';
  static const String exerciceResultat = '/exercices/:exerciceId/resultat';
  static const String devoirComposer = '/devoirs/:devoirId/composer';
  static const String devoirResultat = '/devoirs/:devoirId/resultat';
  static const String olympiadeInscription =
      '/olympiades/:olympiadeId/inscription';
  static const String olympiadeClassement =
      '/olympiades/:olympiadeId/classement';
  static const String departementClassement =
      '/departements/:departementId/classement';
  static const String formationDetail = '/formations/:formationId';
  static const String concoursDetail = '/concours/:concoursId';
  static const String paiement = '/paiement';
  static const String iaChat = '/ia-chat/:coursId';
  static const String forumQuestionDetail = '/forum/questions/:questionId';
  static const String profileEdit = '/profile/edit';

  // ── Partagé ──────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String recharge = '/recharge';

  // ── Enseignant : racine + onglets du shell ──────────────────────
  static const String enseignantDashboard = '/enseignant/dashboard';
  static const String enseignantAdmin = '/enseignant/admin';
  static const String enseignantCoordination = '/enseignant/coordination';
  static const String enseignantCadre = '/enseignant/cadre';
  static const String enseignantPrincipal = '/enseignant/principal';
  static const String enseignantSecondaire = '/enseignant/secondaire';
  static const String enseignantHistorique = '/enseignant/historique';
  static const String enseignantProfil = '/enseignant/profil';

  // ── Enseignant : plein écran ─────────────────────────────────────
  static const String coursDetailEnseignant = '/enseignant/cours/:coursId';
  static const String devoirGererEnseignant = '/enseignant/devoirs/:devoirId/gerer';
  static const String adminDepartementDetail =
      '/enseignant/admin/departements/:departementId';
  static const String adminParcoursDetail =
      '/enseignant/admin/parcours/:parcoursId';
  static const String coordinationDepartementDetail =
      '/enseignant/coordination/departements/:departementId';
  static const String cadreDepartementDetail =
      '/enseignant/cadre/departements/:departementId';
  static const String cadreGestionDemandes =
      '/enseignant/cadre/departements/:departementId/demandes';
}
