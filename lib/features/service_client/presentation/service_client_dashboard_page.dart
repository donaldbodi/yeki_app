// lib/features/service_client/presentation/service_client_dashboard_page.dart
//
// Dashboard Service Client — nichée dans `EnseignantShellPage` (même
// header/bottom nav que les 5 autres rôles enseignant, demande explicite :
// « toute l'interface service client doit être identique aux autres
// interfaces enseignants »). Reconstruite sur `EnseignantDashboardSkeleton`
// (`dashboard_skeleton.dart`), déjà partagé par Coordonnateur/Cadre/
// Principal/Secondaire — mêmes `Scaffold`/`NestedScrollView`/`YkTabs`
// épinglés/`TabBarView`, aucun nouveau composant.
//
// Auparavant route racine autonome (`YkAdaptiveScaffold`, chrome propre,
// P9.5 — premier vrai consommateur de ce composant en prod). Ce chrome
// séparé n'était qu'un choix de l'époque, pas une contrainte technique —
// annulé ici au profit de la structure partagée.
//
// Chaque onglet gère toujours son propre chargement/erreur/état vide
// (`controller.chargementX`/`enErreurX`, inchangé) — le skeleton n'est
// donc jamais gaté au niveau page (`loading`/`errorMessage` toujours
// désactivés), pour ne rien perdre de cette granularité (ex. consulter
// "Répétiteurs" pendant que "Paiements" charge encore).

import 'package:flutter/material.dart';

import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart'
    show EnseignantDashboardSkeleton, YkDashboardHeroBanner, YkDashboardTab;

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

  static const _nbOnglets = 4;

  @override
  void initState() {
    super.initState();
    _controller = ServiceClientController();
    _tabController = TabController(length: _nbOnglets, vsync: this);
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
        final stats = _controller.statistiques;
        return EnseignantDashboardSkeleton(
          loading: false,
          heroCard: stats == null
              ? null
              : YkDashboardHeroBanner(
                  title: 'Demandes en attente',
                  stats: [
                    ('${stats.demandesEnAttentePaiement + stats.demandesEnAttenteRetrait}', 'En attente'),
                    (StatistiquesTab.formatDelai(stats.delaiMoyenMinutesPaiement), 'Délai moyen'),
                    (StatistiquesTab.formatTaux(stats.tauxRefusPaiement), 'Taux de refus'),
                  ],
                ),
          tabController: _tabController,
          tabs: [
            YkDashboardTab(
              label: 'Paiements',
              badge: _controller.paiementsEnAttente > 0 ? _controller.paiementsEnAttente : null,
              body: PaiementsAValiderTab(controller: _controller),
            ),
            YkDashboardTab(
              label: 'Retraits',
              badge: _controller.retraitsEnAttente > 0 ? _controller.retraitsEnAttente : null,
              body: RetraitsAValiderTab(controller: _controller),
            ),
            YkDashboardTab(label: 'Répétiteurs', body: RepetiteursTab(controller: _controller)),
            YkDashboardTab(label: 'Statistiques', body: StatistiquesTab(controller: _controller)),
          ],
        );
      },
    );
  }
}
