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

const Set<String> _authFlowRouteNames = {
  AppRoute.splash,
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
      // l'accueil générique du rôle.
      final redirectTo = state.uri.queryParameters['redirect'];
      if (redirectTo != null && redirectTo.isNotEmpty) {
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
