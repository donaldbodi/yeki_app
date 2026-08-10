// lib/views/pages/apprenants/apprenant_shell.dart
//
// Coque apprenant — refondu en P11.1 (rituel P5.0) : bascule vers
// `YkAdaptiveScaffold`/`YkNavConfig.forRole('apprenant')` (barre du bas en
// compact, navbar gauche déployée en large — exigence explicite du
// ticket), remplace la barre du bas maison (glassmorphism codée en dur,
// `YekiColors`/`YekiGradients` dépréciés) construite ici auparavant.
//
// Ajoute la branche "Accueil" (P11.1) — 6 branches désormais, alignées sur
// `yk_nav_config_apprenant.dart` (CDC_DESIGN §4.2.1) qui prévoyait déjà
// cette destination. Les destinations SANS route de branche
// (Forum/Yéki IA : pas encore de destination globale ; Notifications/
// Portefeuille : routes plein écran hors shell) sont distinguées par
// `_indexDeBranche` — seules les 6 premières déclenchent `goBranch`
// (préserve la pile de navigation propre à chaque onglet), les autres
// utilisent `context.goNamed` standard.
//
// `notificationsProvider` (créé en P3.4, jamais consommé nulle part
// jusqu'ici — confirmé par recherche) est branché ici pour la première
// fois : alimente le badge réel de la destination "Notifications".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/providers/current_user_provider.dart';
import 'package:yeki/core/providers/notifications_provider.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/services/ads_service.dart';

/// Ordre des branches du `StatefulShellRoute` — doit rester synchronisé
/// avec `app_router.dart` (arbre apprenant).
const List<String> _brancheRouteNames = [
  AppRoute.dashboardAccueil,
  AppRoute.dashboardCursus,
  AppRoute.dashboardConcours,
  AppRoute.dashboardFormations,
  AppRoute.dashboardOlympiades,
  AppRoute.dashboardDevoirs,
];

class ApprenantShellPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ApprenantShellPage({super.key, required this.navigationShell});

  String get _selectedRouteName => _brancheRouteNames[navigationShell.currentIndex];

  void _onDestinationTap(BuildContext context, String routeName) {
    final indexDeBranche = _brancheRouteNames.indexOf(routeName);
    if (indexDeBranche != -1) {
      navigationShell.goBranch(indexDeBranche, initialLocation: indexDeBranche == navigationShell.currentIndex);
    } else {
      context.goNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsNonLues = ref.watch(notificationsProvider).valueOrNull ?? 0;
    final profil = ref.watch(currentUserProvider).valueOrNull;
    // Tagging AdMob mineur/enfant (CDC §8.3) — un seul appel dès que la
    // vraie date de naissance est connue, pas à chaque rebuild.
    ref.listen(currentUserProvider, (prev, next) {
      final nouveau = next.valueOrNull;
      if (nouveau != null && prev?.valueOrNull?.dateNaissance != nouveau.dateNaissance) {
        AdsService.instance.init(dateNaissanceIso: nouveau.dateNaissance);
      }
    });
    final nomAffiche = profil == null
        ? 'Apprenant'
        : (profil.firstName.isNotEmpty ? profil.firstName : profil.username);

    return YkAdaptiveScaffold(
      groups: YkNavConfig.forRole('apprenant'),
      selectedRouteName: _selectedRouteName,
      onDestinationTap: (routeName) => _onDestinationTap(context, routeName),
      userName: nomAffiche,
      avatarUrl: profil?.avatar,
      userRole: 'Apprenant',
      onSettings: () => context.pushNamed(AppRoute.profile),
      onLogout: () => authState.clearSession(),
      badges: {'notifications': notificationsNonLues},
      body: navigationShell,
    );
  }
}
