// lib/features/admin_general/presentation/admin_general_page.dart
//
// Administration générale (P9.6) — refonte complète de l'ancien
// `views/pages/enseignants/admin_general_page.dart` (2420 lignes / 93 Ko,
// `http` brut + `SharedPreferences` + styles en dur). Onglets Parcours/
// Départements/Vue globale/Enseignants/Tous les cours (parité de
// fonctionnalités, migrés vers Yk*) + NOUVEL onglet Transactions (tableau
// de bord financier + liste filtrable, `apps/paiement/views.py::
// AdminTransactionsView`/`AdminDashboardFinancierView`).
//
// Reste nichée dans `EnseignantShellPage` (nav + header déjà fournis par ce
// shell partagé, communs à tous les rôles enseignant) — décision explicite
// du projet : seul le STYLE de ce shell est habillé du nouveau design de la
// maquette (voir `enseignant_shell.dart`), jamais sa structure. Un ticket
// antérieur avait détaché cette page vers `YkAdaptiveScaffold` (route racine
// autonome) ; annulé — ça dupliquait le header du shell et cachait le FAB
// « Créer un parcours » derrière la nav flottante.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import 'admin_general_controller.dart';
import 'widgets/departements_tab.dart';
import 'widgets/enseignants_tab.dart';
import 'widgets/parcours_sheets.dart';
import 'widgets/parcours_tab.dart';
import 'widgets/tous_cours_tab.dart';
import 'widgets/transactions_tab.dart';
import 'widgets/vue_globale_tab.dart';

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});

  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage> with SingleTickerProviderStateMixin {
  late final AdminGeneralController _controller;
  late final TabController _tabController;

  static const _onglets = ['Parcours', 'Départements', 'Vue globale', 'Enseignants', 'Tous les cours', 'Transactions'];

  @override
  void initState() {
    super.initState();
    _controller = AdminGeneralController();
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
      animation: Listenable.merge([_controller, _tabController]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: YkColors.background(context),
          body: Column(
            children: [
              YkTabs(controller: _tabController, tabs: [for (final o in _onglets) YkTabItem(label: o)]),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ParcoursTab(controller: _controller),
                    DepartementsTab(controller: _controller),
                    VueGlobaleTab(controller: _controller),
                    EnseignantsTab(controller: _controller),
                    TousCoursTab(controller: _controller),
                    TransactionsTab(controller: _controller),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton(
                  onPressed: () => showCreerParcoursSheet(context, _controller),
                  backgroundColor: YkColors.accent(context),
                  child: Icon(Icons.add, color: YkColors.onAccent(context)),
                )
              : null,
        );
      },
    );
  }
}
