import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

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
  /// (`docs/maquette/YEKI Espace Enseignant.dc.html:115-126,522`) : dégradé
  /// navy 3 tons + cercle décoratif translucide + 3 stats clés en bulles.
  /// Même motif déjà établi cette session pour les cartes héro (Accueil/
  /// Portefeuille, `wallet_page.dart._buildSoldeCard`) — pas une nouvelle
  /// recette. Les 6 stats détaillées restent inchangées dans la grille
  /// ci-dessous : la maquette n'en montre que 3, mais son absence n'est
  /// jamais une instruction de suppression (règle 4).
  Widget _buildBanniereHero(BuildContext context, DashboardStats stats) {
    return YkCard(
      padding: EdgeInsets.zero,
      // Approximation du dégradé maquette (#12405D → #1A5276 → #2C7DA8)
      // avec les tokens YkColors existants — même précédent déjà établi
      // cette session pour les cartes héro (wallet_page.dart._buildSoldeCard),
      // aucune nouvelle couleur en dur introduite.
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
                  'VUE GLOBALE PLATEFORME',
                  style: YkTypography.caption(
                    context,
                  ).copyWith(color: YkColors.textOnPrimary.withValues(alpha: 0.75), fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                SizedBox(height: YkSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _statBulle(context, '${stats.nbParcours}', 'Parcours')),
                    SizedBox(width: YkSpacing.sm),
                    Expanded(child: _statBulle(context, '${stats.nbDepartements}', 'Départements')),
                    SizedBox(width: YkSpacing.sm),
                    Expanded(child: _statBulle(context, '${stats.nbApprenants}', 'Apprenants')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBulle(BuildContext context, String valeur, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.sm),
        color: YkColors.textOnPrimary.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valeur, style: YkTypography.h4(context).copyWith(color: YkColors.textOnPrimary, fontWeight: FontWeight.w800)),
            Text(
              label,
              style: YkTypography.caption(context).copyWith(color: YkColors.textOnPrimary.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
