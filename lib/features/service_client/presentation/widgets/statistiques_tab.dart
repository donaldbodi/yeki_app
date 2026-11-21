import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import '../service_client_controller.dart';

/// Onglet « Statistiques » (P9.5) — demandes en attente, délai moyen, taux
/// de refus. `YkStatCard`, aucune logique de fetch propre (déjà chargé par
/// le contrôleur).
class StatistiquesTab extends StatelessWidget {
  const StatistiquesTab({super.key, required this.controller});

  final ServiceClientController controller;

  // Statiques (pas privées) : réutilisées par `service_client_dashboard_page.
  // dart` pour la bannière héro, même formatage, une seule source de vérité.
  static String formatDelai(double? minutes) {
    if (minutes == null) return '—';
    if (minutes < 60) return '${minutes.round()} min';
    return '${(minutes / 60).toStringAsFixed(1)} h';
  }

  static String formatTaux(double? pourcent) => pourcent == null ? '—' : '${pourcent.toStringAsFixed(1)} %';

  @override
  Widget build(BuildContext context) {
    if (controller.chargementStats) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.grid(itemCount: 6));
    }
    if (controller.enErreurStats || controller.statistiques == null) {
      return YkErrorState(
        message: 'Impossible de charger les statistiques.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerStatistiques,
      );
    }

    final stats = controller.statistiques!;
    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: GridView.count(
        crossAxisCount: YkBreakpoints.of(context) == YkBreakpoint.compact ? 2 : 3,
        mainAxisSpacing: YkSpacing.sm,
        crossAxisSpacing: YkSpacing.sm,
        childAspectRatio: 1.3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          YkStatCard(
            value: '${stats.demandesEnAttentePaiement}',
            label: 'Paiements en attente',
            icon: Icons.payments_outlined,
          ),
          YkStatCard(
            value: '${stats.demandesEnAttenteRetrait}',
            label: 'Retraits en attente',
            icon: Icons.account_balance_wallet_outlined,
          ),
          YkStatCard(
            value: formatDelai(stats.delaiMoyenMinutesPaiement),
            label: 'Délai moyen — paiements',
            icon: Icons.timer_outlined,
          ),
          YkStatCard(
            value: formatDelai(stats.delaiMoyenMinutesRetrait),
            label: 'Délai moyen — retraits',
            icon: Icons.timer_outlined,
          ),
          YkStatCard(
            value: formatTaux(stats.tauxRefusPaiement),
            label: 'Taux de refus — paiements',
            icon: Icons.block_outlined,
          ),
          YkStatCard(
            value: formatTaux(stats.tauxRefusRetrait),
            label: 'Taux de refus — retraits',
            icon: Icons.block_outlined,
          ),
        ],
      ),
    );
  }
}
