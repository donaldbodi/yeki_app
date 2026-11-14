import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'auth_state.dart';
import 'route_guard_metadata.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// Seule fonction de branchement par rôle qui subsiste dans tout le
/// projet — remplace `YekiAuth._widgetFromRole` (apprenant/enseignant,
/// main.dart) ET le `switch` interne de `EnseignantHomePage._fetchUserRole`
/// (les 5 dashboards enseignant). `service_client` a son propre dashboard
/// à onglets depuis P9.5 (`ServiceClientDashboardPage`) — seul tout rôle
/// non reconnu tombe encore dans le seau de repli générique
/// `enseignantSecondaire`.
String homePathForRole(String? role) {
  switch (role) {
    case 'apprenant':
      return AppPath.dashboardAccueil;
    case 'admin':
      return AppPath.enseignantAdmin;
    case 'enseignant_admin':
      return AppPath.enseignantCoordination;
    case 'enseignant_cadre':
      return AppPath.enseignantCadre;
    case 'enseignant_principal':
      return AppPath.enseignantPrincipal;
    case 'service_client':
      return AppPath.serviceClientDashboard;
    default:
      // 'enseignant' ou tout rôle inconnu.
      return AppPath.enseignantSecondaire;
  }
}

/// Vérifie qu'un chemin capturé par un ancien `?redirect=` reste autorisé
/// pour [role] avant de lui faire confiance (bug corrigé : bascule de rôle
/// par déconnexion/reconnexion, voir le commentaire dans [redirect]).
/// Réutilise `RouteConfiguration.findMatch` (API publique de `go_router`,
/// déjà exposée via `GoRouter.of(context).configuration`) pour retrouver
/// le NOM de route correspondant au chemin, puis la même table d'accès que
/// tout le reste de ce fichier — pas une nouvelle heuristique.
bool _redirectAutorisePourRole(BuildContext context, String path, String? role) {
  try {
    final matchList = GoRouter.of(context).configuration.findMatch(Uri.parse(path));
    if (matchList.isError) return false;
    final route = matchList.lastOrNull?.route;
    final name = route is GoRoute ? route.name : null;
    final access = name != null ? routeAccessByName[name] : null;
    return access != null && access.allows(role);
  } catch (_) {
    return false;
  }
}

const Set<String> _authFlowRouteNames = {
  AppRoute.onboarding,
  AppRoute.login,
  AppRoute.register,
  AppRoute.forgotPassword,
};

/// Callback `GoRouter.redirect` — voir le plan P3.3 §3 pour la logique
/// complète, étape par étape.
String? redirect(BuildContext context, GoRouterState state) {
  final snapshot = authState.value;
  // `state.name` n'est PAS fiable ici : le callback `GoRouter(redirect:)`
  // top-level reçoit un `GoRouterState` construit AVANT résolution
  // complète de la correspondance de route, où `name` est toujours `null`
  // (confirmé par lecture du code source go_router — voir le commentaire
  // sur `GoRouterState.name` : « This can be null for GoRouterState pass
  // into top level redirect »). `state.topRoute` est la `GoRoute`
  // effectivement appariée et expose son `.name` de façon fiable, y
  // compris ici — c'est la source de vérité correcte pour tout ce
  // fichier.
  final name = state.topRoute?.name;

  // 1. Pas encore démarré → écran splash (lecture SharedPreferences en cours).
  if (!snapshot.bootstrapped) {
    return state.matchedLocation == AppPath.splash ? null : AppPath.splash;
  }

  // 1bis. Bootstrap terminé mais toujours sur /splash — bug corrigé
  // (splash bloqué à l'infini) : contrairement à login/register/
  // onboarding (dans `_authFlowRouteNames`, où rester est légitime pour
  // un visiteur non connecté), /splash n'est JAMAIS une destination
  // valide une fois le bootstrap fini. `AppRoute.splash` était
  // auparavant inclus dans `_authFlowRouteNames` : pour un visiteur non
  // authentifié, la branche « route publique » ci-dessous renvoyait
  // `null` (« aucune redirection nécessaire ») — et comme on est déjà
  // sur `/splash`, l'app y restait indéfiniment, sans jamais être
  // poussée vers `/login`.
  if (name == AppRoute.splash) {
    // Bug corrigé (onboarding jamais affiché) : un visiteur non connecté
    // partait directement sur /login, et la connexion marque ensuite
    // l'onboarding comme vu — l'écran de bienvenue n'apparaissait donc à
    // personne. Le premier lancement passe désormais par l'onboarding,
    // qui renvoie ensuite vers /login (ou /register).
    if (!snapshot.onboardingDone) return AppPath.onboarding;
    if (!snapshot.isAuthenticated) return AppPath.login;
    return homePathForRole(snapshot.role);
  }

  // /design-system : debug uniquement, jamais par rôle.
  if (name == AppRoute.designSystem) {
    return kDebugMode ? null : AppPath.notFound;
  }

  final access = name != null ? routeAccessByName[name] : null;

  // 2. Route publique → toujours autorisée, court-circuite tout le reste.
  if (access == RouteAccess.public || _authFlowRouteNames.contains(name)) {
    // Un utilisateur déjà connecté qui revoit une route du flux auth
    // (bouton retour, favori) est renvoyé vers l'accueil de son rôle —
    // étape 5, traitée ici pour éviter une double lecture de `name`.
    if (snapshot.isAuthenticated &&
        snapshot.onboardingDone &&
        _authFlowRouteNames.contains(name) &&
        name != AppRoute.onboarding) {
      // Retour post-connexion : si /login a été atteint via l'étape 3
      // ci-dessous (redirection depuis une route protégée), on revient
      // exactement là où l'utilisateur voulait aller plutôt que sur
      // l'accueil générique du rôle — SAUF si ce paramètre est périmé
      // (bug corrigé : bascule de rôle par déconnexion/reconnexion). Ce
      // `redirect` a été attaché à /login par la déconnexion FORCÉE de la
      // session précédente (étape 3 ci-dessous) ; s'il est réutilisé tel
      // quel après une connexion avec un rôle DIFFÉRENT, l'app charge la
      // page de l'ancien compte au lieu de `homePathForRole` du nouveau —
      // d'où la validation contre le rôle réellement connecté avant de
      // lui faire confiance.
      final redirectTo = state.uri.queryParameters['redirect'];
      if (redirectTo != null &&
          redirectTo.isNotEmpty &&
          _redirectAutorisePourRole(context, redirectTo, snapshot.role)) {
        return redirectTo;
      }
      return homePathForRole(snapshot.role);
    }
    return null;
  }

  // 3. Non authentifié, route non publique → /login avec retour post-connexion.
  if (!snapshot.isAuthenticated) {
    final target = state.uri.toString();
    return '${AppPath.login}?redirect=${Uri.encodeComponent(target)}';
  }

  // 4. Authentifié mais onboarding non fait.
  if (!snapshot.onboardingDone) {
    return AppPath.onboarding;
  }

  // 7. Rôle insuffisant pour la route ciblée.
  if (access != null && !access.allows(snapshot.role)) {
    return AppPath.forbidden;
  }

  // 8. Autorisé.
  return null;
}
