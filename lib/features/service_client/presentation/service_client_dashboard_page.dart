// lib/features/service_client/presentation/service_client_dashboard_page.dart
//
// Dashboard Service Client (P9.5) — nouveau, au même niveau que les autres
// interfaces de rôle (`YkAdaptiveScaffold`, comme demandé explicitement
// par le ticket). Premier VRAI consommateur en production de
// `YkAdaptiveScaffold`/`YkDataTable` (confirmé : zéro usage hors showcase
// avant ce ticket) — on suit le ticket tel qu'écrit malgré l'absence d'un
// "autre" dashboard déjà migré à imiter.
//
// Route racine (`parentNavigatorKey: rootNavigatorKey`), PAS nichée dans
// `EnseignantShellPage` (legacy, chrome à onglets Accueil/Historique/
// Profil) : `YkAdaptiveScaffold` construit son propre chrome complet
// (barre du bas/rail/navbar) — l'imbriquer dans un second chrome créerait
// une double navigation cassée. `service_client` bascule directement ici
// via `homePathForRole()`.
//
// Notification : push explicitement HORS PÉRIMÈTRE (voir
// docs/ecarts/wallet.md-like note ci-dessous) — `lib/services/
// push_notification_service.dart` a une clé VAPID placeholder littérale et
// aucun endpoint backend d'enregistrement de token n'existe. Seul le badge
// in-app (compteur de demandes en attente, `notifyListeners` du
// contrôleur) est branché ici.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';

import 'service_client_controller.dart';
import 'widgets/paiements_a_valider_tab.dart';
import 'widgets/repetiteurs_tab.dart';
import 'widgets/retraits_a_valider_tab.dart';
import 'widgets/statistiques_tab.dart';

class ServiceClientDashboardPage extends StatefulWidget {
  const ServiceClientDashboardPage({super.key});

  @override
  State<ServiceClientDashboardPage> createState() => _ServiceClientDashboardPageState();
}

class _ServiceClientDashboardPageState extends State<ServiceClientDashboardPage>
    with SingleTickerProviderStateMixin {
  late final ServiceClientController _controller;
  late final TabController _tabController;

  static const _onglets = ['Paiements', 'Retraits', 'Répétiteurs', 'Statistiques'];

  @override
  void initState() {
    super.initState();
    _controller = ServiceClientController();
    _tabController = TabController(length: _onglets.length, vsync: this);
    _controller.chargerTout();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return YkAdaptiveScaffold(
          groups: YkNavConfig.forRole('service_client'),
          selectedRouteName: AppRoute.serviceClientDashboard,
          onDestinationTap: (routeName) => context.goNamed(routeName),
          userName: _controller.userName,
          userRole: 'Service Client',
          onSettings: () => context.pushNamed(AppRoute.profile),
          onLogout: () => authState.clearSession(),
          badges: {'serviceClientDemandes': _controller.demandesEnAttenteTotal},
          body: Scaffold(
            backgroundColor: YkColors.background(context),
            appBar: AppBar(
              title: const Text('Service Client'),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [for (final onglet in _onglets) Tab(text: onglet)],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                PaiementsAValiderTab(controller: _controller),
                RetraitsAValiderTab(controller: _controller),
                RepetiteursTab(controller: _controller),
                StatistiquesTab(controller: _controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
