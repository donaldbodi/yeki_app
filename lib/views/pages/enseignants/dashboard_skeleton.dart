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
          if (heroCard != null)
            SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, 0), child: heroCard),
            ),
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

/// Bannière héro dégradée — maquette « Espace Enseignant »
/// (`docs/maquette/YEKI Espace Enseignant.dc.html:115-126`, dégradé
/// `#12405D→#1A5276→#2C7DA8` + cercle décoratif translucide + bulles de
/// stats), déjà établie pour Admin Général
/// (`vue_globale_tab.dart._buildBanniereHero`, extraite ici pour être
/// réutilisée par les autres dashboards enseignant sans dupliquer le
/// motif). Se branche sur le paramètre `heroCard` déjà existant
/// d'[EnseignantDashboardSkeleton] (jusqu'ici inutilisé par ces 4
/// dashboards) — aucun changement de structure, juste un élément visuel
/// déjà prévu par ce squelette.
class YkDashboardHeroBanner extends StatelessWidget {
  const YkDashboardHeroBanner({super.key, required this.title, required this.stats});

  final String title;

  /// 2 ou 3 couples (valeur, libellé) — même format que la maquette.
  final List<(String, String)> stats;

  // Pas de marge propre (contrairement à un premier essai) — le contexte
  // d'appel varie (liste déjà paddée pour `vue_globale_tab.dart`, sliver
  // nu pour `heroCard`) : chaque appelant applique la marge qui lui
  // convient, cette bannière ne gère que son propre contenu.
  @override
  Widget build(BuildContext context) {
    return YkCard(
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [YkColors.primary800, YkColors.primary700, YkColors.primary500],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: ClipOval(
              child: Container(width: 140, height: 140, color: YkColors.textOnPrimary.withValues(alpha: 0.08)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(YkSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: YkTypography.caption(
                    context,
                  ).copyWith(color: YkColors.textOnPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                SizedBox(height: YkSpacing.sm),
                Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) SizedBox(width: YkSpacing.sm),
                      Expanded(child: _bulle(context, stats[i].$1, stats[i].$2)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulle(BuildContext context, String valeur, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.sm),
        color: YkColors.textOnPrimary.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valeur, style: YkTypography.h4(context).copyWith(color: YkColors.textOnPrimary, fontWeight: FontWeight.w800)),
            Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textOnPrimary.withValues(alpha: 0.8))),
          ],
        ),
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
