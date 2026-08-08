import 'route_names.dart';

/// Les 6 rôles backend qui ne sont pas `apprenant` (`Profile.USER_TYPES`,
/// `apps/accounts/models.py`). `service_client` a son propre dashboard
/// (`AppRoute.serviceClientDashboard`, voir `guards.dart` —
/// `homePathForRole`) nichée dans le même `EnseignantShellPage` que les
/// autres rôles de ce set — il utilise donc réellement les routes
/// `enseignantAny` partagées (profil, historique...), pas seulement "au
/// cas où".
const Set<String> kEnseignantRoles = {
  'admin',
  'service_client',
  'enseignant_admin',
  'enseignant_cadre',
  'enseignant_principal',
  'enseignant',
};

enum _AccessKind { public, anyAuthenticated, apprenant, enseignantAny, roles }

/// Contrôle d'accès par route. go_router n'a pas de RBAC par route
/// intégré — cette classe + la table `routeAccessByName` ci-dessous sont
/// le mécanisme utilisé par `guards.dart` pour décider d'un 403.
class RouteAccess {
  final _AccessKind _kind;
  final Set<String>? _allowedRoles;

  const RouteAccess._(this._kind, [this._allowedRoles]);

  /// Accessible sans authentification (écrans auth, /403, /404, splash).
  static const RouteAccess public = RouteAccess._(_AccessKind.public);

  /// Accessible à tout utilisateur authentifié, quel que soit son rôle
  /// (profil, notifications, wallet...).
  static const RouteAccess anyAuthenticated =
      RouteAccess._(_AccessKind.anyAuthenticated);

  /// Réservé au rôle `apprenant`.
  static const RouteAccess apprenant = RouteAccess._(_AccessKind.apprenant);

  /// Réservé à l'un des 6 rôles enseignant-ish (voir [kEnseignantRoles]).
  static const RouteAccess enseignantAny =
      RouteAccess._(_AccessKind.enseignantAny);

  /// Réservé à un sous-ensemble précis de rôles (ex. `admin` seul).
  factory RouteAccess.roles(Set<String> allowed) =>
      RouteAccess._(_AccessKind.roles, allowed);

  /// `null` = pas encore authentifié (seul [public] doit renvoyer `true`
  /// dans ce cas — vérifié séparément par `guards.dart` avant d'appeler
  /// cette méthode pour les autres cas).
  bool allows(String? role) {
    switch (_kind) {
      case _AccessKind.public:
        return true;
      case _AccessKind.anyAuthenticated:
        return role != null;
      case _AccessKind.apprenant:
        return role == 'apprenant';
      case _AccessKind.enseignantAny:
        return role != null && kEnseignantRoles.contains(role);
      case _AccessKind.roles:
        return role != null && _allowedRoles!.contains(role);
    }
  }
}

/// Table indexée par NOM de route (pas par chemin — un nom est stable,
/// un chemin peut changer).
final Map<String, RouteAccess> routeAccessByName = {
  // Racine / auth — publiques.
  AppRoute.splash: RouteAccess.public,
  AppRoute.onboarding: RouteAccess.public,
  AppRoute.login: RouteAccess.public,
  AppRoute.register: RouteAccess.public,
  AppRoute.forgotPassword: RouteAccess.public,
  AppRoute.forbidden: RouteAccess.public,
  AppRoute.notFound: RouteAccess.public,
  // designSystem : géré à part par guards.dart (kDebugMode), pas par rôle.
  AppRoute.designSystem: RouteAccess.public,

  // Apprenant.
  AppRoute.dashboardAccueil: RouteAccess.apprenant,
  AppRoute.dashboardCursus: RouteAccess.apprenant,
  AppRoute.dashboardConcours: RouteAccess.apprenant,
  AppRoute.dashboardFormations: RouteAccess.apprenant,
  AppRoute.dashboardOlympiades: RouteAccess.apprenant,
  AppRoute.dashboardDevoirs: RouteAccess.apprenant,
  AppRoute.repetiteurs: RouteAccess.apprenant,
  // Réglages génériques (mot de passe, notifications, langue,
  // déconnexion...) — rien de spécifique à l'apprenant ; ProfilPage,
  // partagé par les deux arbres, y renvoie.
  AppRoute.settings: RouteAccess.anyAuthenticated,
  AppRoute.coursDetail: RouteAccess.apprenant,
  AppRoute.leconDetail: RouteAccess.apprenant,
  AppRoute.leconLecture: RouteAccess.apprenant,
  AppRoute.exercicePasser: RouteAccess.apprenant,
  AppRoute.exerciceResultat: RouteAccess.apprenant,
  AppRoute.devoirComposer: RouteAccess.apprenant,
  AppRoute.devoirResultat: RouteAccess.apprenant,
  AppRoute.olympiadeInscription: RouteAccess.apprenant,
  AppRoute.olympiadeClassement: RouteAccess.apprenant,
  AppRoute.departementClassement: RouteAccess.apprenant,
  AppRoute.formationDetail: RouteAccess.apprenant,
  AppRoute.concoursDetail: RouteAccess.apprenant,
  AppRoute.paiement: RouteAccess.apprenant,
  AppRoute.iaChat: RouteAccess.apprenant,
  AppRoute.forumQuestionDetail: RouteAccess.apprenant,
  AppRoute.profileEdit: RouteAccess.anyAuthenticated,

  // Partagé.
  AppRoute.profile: RouteAccess.anyAuthenticated,
  AppRoute.notifications: RouteAccess.anyAuthenticated,
  AppRoute.wallet: RouteAccess.anyAuthenticated,
  AppRoute.recharge: RouteAccess.anyAuthenticated,
  AppRoute.retrait: RouteAccess.roles({'enseignant_cadre'}),
  AppRoute.serviceClientDashboard: RouteAccess.roles({'service_client'}),

  // Enseignant — onglets/alias.
  AppRoute.enseignantDashboard: RouteAccess.enseignantAny,
  AppRoute.enseignantAdmin: RouteAccess.roles({'admin'}),
  AppRoute.enseignantCoordination: RouteAccess.roles({'enseignant_admin'}),
  AppRoute.enseignantCadre: RouteAccess.roles({'enseignant_cadre'}),
  AppRoute.enseignantPrincipal: RouteAccess.roles({'enseignant_principal'}),
  // Seau de repli générique : accessible à tout rôle enseignant-ish,
  // pas seulement 'enseignant'/'service_client' (voir homePathForRole
  // dans guards.dart — un rôle non reconnu y atterrit aussi).
  AppRoute.enseignantSecondaire: RouteAccess.enseignantAny,
  AppRoute.enseignantHistorique: RouteAccess.enseignantAny,
  AppRoute.enseignantProfil: RouteAccess.enseignantAny,

  // Enseignant — plein écran.
  AppRoute.coursDetailEnseignant: RouteAccess.enseignantAny,
  AppRoute.adminDepartementDetail: RouteAccess.roles({'admin'}),
  AppRoute.adminParcoursDetail: RouteAccess.roles({'admin'}),
  AppRoute.coordinationDepartementDetail:
      RouteAccess.roles({'enseignant_admin'}),
  AppRoute.cadreDepartementDetail: RouteAccess.roles({'enseignant_cadre'}),
  AppRoute.cadreGestionDemandes: RouteAccess.roles({'enseignant_cadre'}),
};
