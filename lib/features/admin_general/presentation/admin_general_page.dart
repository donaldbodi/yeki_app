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
// Navbar identique à la maquette (ticket ultérieur) : `YkAdaptiveScaffold`
// construit désormais son propre chrome complet (barre de nav en pilule
// verre) — route racine autonome (`AppRoute.enseignantAdmin`,
// `app_router.dart`), plus nichée dans `EnseignantShellPage` (legacy).
// Même patron que le premier vrai consommateur en production,
// `service_client_dashboard_page.dart` (P9.5).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';

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

  /// 2 initiales depuis `_controller.userName` — même motif que
  /// `accueil_page.dart._initiales`, adapté à un nom complet unique
  /// (« Prénom Nom ») plutôt que 2 champs séparés.
  String get _initiales {
    final mots = _controller.userName.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    final premiere = mots.first[0].toUpperCase();
    final derniere = mots.length > 1 ? mots.last[0].toUpperCase() : '';
    return '$premiere$derniere';
  }

  /// Même motif que `accueil_page.dart._salutation`.
  String get _salutation {
    final heure = DateTime.now().hour;
    if (heure < 12) return 'Bonjour';
    if (heure < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

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
        return YkAdaptiveScaffold(
          groups: YkNavConfig.forRole('admin'),
          selectedRouteName: AppRoute.enseignantAdmin,
          onDestinationTap: (routeName) => context.goNamed(routeName),
          userName: _controller.userName,
          userRole: 'Administrateur Général',
          onSettings: () => context.pushNamed(AppRoute.profile),
          onLogout: () => authState.clearSession(),
          body: Scaffold(
            backgroundColor: YkColors.background(context),
            body: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, YkSpacing.sm),
                  child: _buildHeader(context),
                ),
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
          ),
        );
      },
    );
  }

  /// Header (nom + salutation) — `AdminGeneralPage` n'en avait plus depuis
  /// le passage à `YkAdaptiveScaffold` (nav seulement, pas de barre
  /// supérieure). Même patron que `accueil_page.dart._buildAppBar`
  /// (100% tokens : `YkGradientBackground`/`YkTypography`/`YkColors`) —
  /// pas celui de l'ancien `enseignant_shell.dart._buildMobileHeader`
  /// (dégradé en dur, composants privés), pour rester harmonieux avec le
  /// reste de cette page déjà entièrement sur tokens.
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 44,
            height: 44,
            child: YkGradientBackground(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [YkColors.primary700, YkColors.primary500],
              ),
              child: Center(
                child: Text(_initiales, style: YkTypography.label(context).copyWith(color: YkColors.textOnPrimary)),
              ),
            ),
          ),
        ),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_salutation 👋', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
              Text(_controller.userName, style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            ],
          ),
        ),
        YkBadge(variant: YkBadgeVariant.label, label: 'ADMIN GÉNÉRAL', color: YkColors.violet),
      ],
    );
  }
}
