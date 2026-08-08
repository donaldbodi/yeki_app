// lib/views/pages/enseignants/interface_enseignant_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// RÔLES ENSEIGNANT — enum + mapping depuis le rôle backend brut.
//
// L'ancien widget `EnseignantHomePage` (chrome + logique de choix de
// dashboard) a été supprimé lors du passage à go_router (P3.3) :
// - le chrome (barre latérale/basse) vit maintenant dans
//   `enseignant_shell.dart` (`EnseignantShellPage`) ;
// - le choix du dashboard concret à afficher est résolu par
//   `guards.dart`/`app_router.dart` (route `/enseignant/dashboard`,
//   alias qui redirige via `homePathForRole`), plus par les rôles déjà
//   en cache dans `authState` — plus par un appel API dédié.
//
// L'enum `RoleEnseignant` et `roleEnseignantFromBackend` restent ici et
// sont toujours utilisés ailleurs (gating `_canEdit`, construction de
// `DetailCoursEnseignantPage(role: ...)`).
// ═══════════════════════════════════════════════════════════════════════════

enum RoleEnseignant {
  administrateurGeneral,
  enseignantAdministrateur,
  enseignantCadre,
  enseignantPrincipal,
  enseignantSecondaire,
  serviceClient,
}

/// Convertit le rôle backend brut (`Profile.USER_TYPES`) en
/// `RoleEnseignant`. Tout rôle non explicitement reconnu (`enseignant`
/// nu, ou une valeur future inconnue) tombe dans le seau de repli
/// `enseignantSecondaire` — même logique que `homePathForRole` dans
/// `guards.dart`, à garder synchronisée avec elle.
RoleEnseignant roleEnseignantFromBackend(String? role) {
  switch (role) {
    case 'admin':
      return RoleEnseignant.administrateurGeneral;
    case 'enseignant_admin':
      return RoleEnseignant.enseignantAdministrateur;
    case 'enseignant_cadre':
      return RoleEnseignant.enseignantCadre;
    case 'enseignant_principal':
      return RoleEnseignant.enseignantPrincipal;
    case 'service_client':
      return RoleEnseignant.serviceClient;
    default:
      return RoleEnseignant.enseignantSecondaire;
  }
}
