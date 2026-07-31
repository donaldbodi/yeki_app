// lib/views/pages/enseignants/dashboard_skeleton.dart
//
// Squelette partagé des 4 tableaux de bord enseignants (P11.5) — absorbe
// la coquille dupliquée dans `secondaire_dashboard_page.dart`/
// `principal_dashboard_page.dart`/`cadre_dashboard_page.dart`/
// `enseignant_admin_dashboard_page.dart` : `Scaffold` + FAB optionnel +
// état chargement/erreur + `NestedScrollView` (héros optionnel + `YkTabs`
// épinglés) + `TabBarView`. Chaque dashboard garde son propre chargement
// de données (`DashboardRepository`) et ses propres onglets/actions —
// leurs contenus divergent trop d'un grade à l'autre (voir fiche d'écart)
// pour être généralisés au-delà de cette coquille.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

export 'package:yeki/utils/color_utils.dart' show couleurDepuisHex;

class YkDashboardTab {
  const YkDashboardTab({required this.label, this.badge, required this.body});

  final String label;
  final int? badge;
  final Widget body;
}

class EnseignantDashboardSkeleton extends StatelessWidget {
  const EnseignantDashboardSkeleton({
    super.key,
    required this.loading,
    this.errorMessage,
    this.onRetry,
    this.heroCard,
    required this.tabController,
    required this.tabs,
    this.fab,
  });

  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? heroCard;
  final TabController tabController;
  final List<YkDashboardTab> tabs;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        body: Center(child: YkProgress(shape: YkProgressShape.circular)),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        body: YkEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Erreur de chargement',
          message: errorMessage!,
          actionLabel: onRetry != null ? 'Réessayer' : null,
          onAction: onRetry,
        ),
      );
    }

    return Scaffold(
      backgroundColor: YkColors.background(context),
      floatingActionButton: fab,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          if (heroCard != null) SliverToBoxAdapter(child: heroCard),
          SliverPersistentHeader(
            pinned: true,
            delegate: YkPinnedHeader(
              child: Container(
                color: YkColors.background(context),
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
                child: YkTabs(
                  controller: tabController,
                  tabs: [for (final t in tabs) YkTabItem(label: t.label, badge: t.badge)],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(controller: tabController, children: [for (final t in tabs) t.body]),
      ),
    );
  }
}

/// Grille 2×2 de `YkStatCard` — remplace le patron `GridView.count(
/// crossAxisCount: 2, ...)` de `_StatItem`/`_SI`/`_StatItem` dupliqué dans
/// les 4 dashboards.
class YkDashboardStatGrid extends StatelessWidget {
  const YkDashboardStatGrid({super.key, required this.cards});

  final List<YkStatCard> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: YkSpacing.sm,
      mainAxisSpacing: YkSpacing.sm,
      childAspectRatio: 1.5,
      children: cards,
    );
  }
}
