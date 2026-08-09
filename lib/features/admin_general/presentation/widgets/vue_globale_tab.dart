import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart' show YkDashboardHeroBanner;

import '../../data/admin_general_models.dart';
import '../admin_general_controller.dart';

/// Onglet « Vue globale » (P9.6) — 6 statistiques d'ensemble + top
/// enseignants (score = somme brute des points d'exercices de leurs cours,
/// voir `ClassementService` côté backend).
class VueGlobaleTab extends StatelessWidget {
  const VueGlobaleTab({super.key, required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementDashboard) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.grid(itemCount: 6));
    }
    if (controller.enErreurDashboard) {
      return YkErrorState(
        message: 'Impossible de charger les statistiques.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerDashboard,
      );
    }
    final stats = controller.dashboard?.stats;
    final topEnseignants = controller.dashboard?.topEnseignants ?? const [];
    if (stats == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: controller.chargerDashboard,
      child: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        children: [
          _buildBanniereHero(context, stats),
          SizedBox(height: YkSpacing.lg),
          GridView.count(
            crossAxisCount: YkBreakpoints.of(context) == YkBreakpoint.compact ? 2 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: YkSpacing.sm,
            mainAxisSpacing: YkSpacing.sm,
            childAspectRatio: 1.4,
            children: [
              YkStatCard(value: '${stats.nbParcours}', label: 'Parcours', icon: Icons.route),
              YkStatCard(value: '${stats.nbDepartements}', label: 'Départements', icon: Icons.domain),
              YkStatCard(value: '${stats.nbCours}', label: 'Cours', icon: Icons.book),
              YkStatCard(value: '${stats.nbApprenants}', label: 'Apprenants', icon: Icons.people),
              YkStatCard(value: '${stats.nbEnseignants}', label: 'Enseignants', icon: Icons.person_outline),
              YkStatCard(value: '${stats.nbLecons}', label: 'Leçons', icon: Icons.play_lesson),
            ],
          ),
          if (topEnseignants.isNotEmpty) ...[
            SizedBox(height: YkSpacing.lg),
            YkSection(
              title: 'Top enseignants',
              child: Column(
                children: [
                  for (final entry in topEnseignants.asMap().entries)
                    Padding(
                      padding: EdgeInsets.only(bottom: YkSpacing.xs),
                      child: YkCard(
                        variant: YkCardVariant.filled,
                        child: Row(
                          children: [
                            YkAvatar(fallbackText: '${entry.key + 1}', size: YkAvatarSize.sm),
                            SizedBox(width: YkSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.nom,
                                    style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                                  ),
                                  Text(
                                    entry.value.role,
                                    style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.value.score.toStringAsFixed(1)}/20',
                              style: YkTypography.label(context).copyWith(color: YkColors.accent(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bannière héro dégradée — maquette « Espace Enseignant », rôle admin
  /// (`docs/maquette/YEKI Espace Enseignant.dc.html:115-126,522`). Délègue
  /// désormais à `YkDashboardHeroBanner` (`dashboard_skeleton.dart`),
  /// extraite d'ici pour être réutilisée par les autres dashboards
  /// enseignant (rule 1 — une seule source de vérité pour ce motif visuel,
  /// maintenant utilisé 6 fois). Les 6 stats détaillées restent inchangées
  /// dans la grille ci-dessous : la maquette n'en montre que 3, mais son
  /// absence n'est jamais une instruction de suppression (règle 4).
  Widget _buildBanniereHero(BuildContext context, DashboardStats stats) {
    return YkDashboardHeroBanner(
      title: 'Vue globale plateforme',
      stats: [
        ('${stats.nbParcours}', 'Parcours'),
        ('${stats.nbDepartements}', 'Départements'),
        ('${stats.nbApprenants}', 'Apprenants'),
      ],
    );
  }
}
