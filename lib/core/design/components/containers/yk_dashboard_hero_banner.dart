// lib/core/design/components/containers/yk_dashboard_hero_banner.dart
//
// Bannière héro dégradée — maquette « Espace Enseignant »
// (`docs/maquette/YEKI Espace Enseignant.dc.html:115-126`, dégradé
// `#12405D→#1A5276→#2C7DA8` + cercle décoratif translucide + bulles de
// stats). Extraite depuis `lib/views/pages/enseignants/dashboard_skeleton.dart`
// (où elle a été introduite pour les dashboards enseignant) vers le
// design system partagé : le même motif sert désormais aussi des écrans
// apprenant (Devoirs, Olympiades — aucune raison de le dupliquer, règle
// 1). `dashboard_skeleton.dart` ré-exporte ce fichier pour que les
// dashboards enseignant continuent de fonctionner sans changement.
import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import 'yk_card.dart';

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
