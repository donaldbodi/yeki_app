import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';

import '../admin_general_controller.dart';

/// Onglet « Départements » (P9.6) — liste, navigation vers le détail.
class DepartementsTab extends StatelessWidget {
  const DepartementsTab({super.key, required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementDashboard) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurDashboard) {
      return YkErrorState(
        message: 'Impossible de charger les départements.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerDashboard,
      );
    }
    final departements = controller.dashboard?.departements ?? const [];
    if (departements.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun département',
        message: 'Créez un département depuis le détail d\'un parcours.',
        icon: Icons.domain_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.chargerDashboard,
      child: ListView.builder(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: departements.length,
        itemBuilder: (_, i) {
          final d = departements[i];
          return Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.sm),
            child: YkCard(
              onTap: () => context.pushNamed(
                AppRoute.adminDepartementDetail,
                pathParameters: {'departementId': d.id.toString()},
                queryParameters: {'departementNom': d.nom, 'parcoursNom': d.parcoursNom},
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                        Text(
                          '${d.nbCours} cours · ${d.nbApprenants} apprenants',
                          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        if (d.parcoursNom.isNotEmpty)
                          Text(
                            'Parcours : ${d.parcoursNom}',
                            style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                          ),
                        if (d.cadre != null)
                          Text(
                            'Cadre : ${d.cadre!.nom}',
                            style: YkTypography.caption(context).copyWith(color: YkColors.accent(context)),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: YkColors.accent(context)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
