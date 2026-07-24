/// Noms de route — utilisés partout via `context.goNamed`/`pushNamed`/
/// `replaceNamed`. Aucun écran ne doit jamais écrire un chemin en dur ;
/// les chemins eux-mêmes vivent uniquement dans `route_paths.dart`, pour
/// pouvoir changer sans toucher aux sites d'appel.
abstract final class AppRoute {
  // ── Racine / auth ──────────────────────────────────────────────
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String forbidden = 'forbidden';
  static const String notFound = 'notFound';
  static const String designSystem = 'designSystem';

  // ── Apprenant : onglets du shell ───────────────────────────────
  static const String dashboardCursus = 'dashboardCursus';
  static const String dashboardConcours = 'dashboardConcours';
  static const String dashboardFormations = 'dashboardFormations';
  static const String dashboardOlympiades = 'dashboardOlympiades';
  static const String dashboardDevoirs = 'dashboardDevoirs';

  // ── Apprenant : plein écran ─────────────────────────────────────
  static const String repetiteurs = 'repetiteurs';
  static const String settings = 'settings';
  static const String coursDetail = 'coursDetail';
  static const String leconDetail = 'leconDetail';
  static const String leconLecture = 'leconLecture';
  static const String exercicePasser = 'exercicePasser';
  static const String exerciceResultat = 'exerciceResultat';
  static const String devoirComposer = 'devoirComposer';
  static const String devoirResultat = 'devoirResultat';
  static const String olympiadeInscription = 'olympiadeInscription';
  static const String olympiadeClassement = 'olympiadeClassement';
  static const String departementClassement = 'departementClassement';
  static const String formationDetail = 'formationDetail';
  static const String concoursDetail = 'concoursDetail';
  static const String paiement = 'paiement';
  static const String iaChat = 'iaChat';
  static const String forumQuestionDetail = 'forumQuestionDetail';
  static const String profileEdit = 'profileEdit';

  // ── Partagé (apprenant + enseignant) ────────────────────────────
  static const String profile = 'profile';
  static const String notifications = 'notifications';
  static const String wallet = 'wallet';
  static const String recharge = 'recharge';

  // ── Enseignant : onglets du shell + alias de dashboard ──────────
  static const String enseignantDashboard = 'enseignantDashboard';
  static const String enseignantAdmin = 'enseignantAdmin';
  static const String enseignantCoordination = 'enseignantCoordination';
  static const String enseignantCadre = 'enseignantCadre';
  static const String enseignantPrincipal = 'enseignantPrincipal';
  static const String enseignantSecondaire = 'enseignantSecondaire';
  static const String enseignantHistorique = 'enseignantHistorique';
  static const String enseignantProfil = 'enseignantProfil';

  // ── Enseignant : plein écran ─────────────────────────────────────
  static const String coursDetailEnseignant = 'coursDetailEnseignant';
  static const String devoirGererEnseignant = 'devoirGererEnseignant';
  static const String adminDepartementDetail = 'adminDepartementDetail';
  static const String adminParcoursDetail = 'adminParcoursDetail';
  static const String coordinationDepartementDetail =
      'coordinationDepartementDetail';
  static const String cadreDepartementDetail = 'cadreDepartementDetail';
  static const String cadreGestionDemandes = 'cadreGestionDemandes';
}
