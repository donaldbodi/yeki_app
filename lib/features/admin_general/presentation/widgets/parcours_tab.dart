import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/features/admin_general/data/admin_general_models.dart';

import '../admin_general_controller.dart';
import 'parcours_sheets.dart';

/// Onglet « Parcours » (P9.6) — liste, création (FAB, voir
/// [AdminGeneralPage]), édition, nomination/changement d'administrateur.
class ParcoursTab extends StatelessWidget {
  const ParcoursTab({super.key, required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementDashboard) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurDashboard) {
      return YkErrorState(
        message: 'Impossible de charger les parcours.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerDashboard,
      );
    }
    final parcours = controller.dashboard?.parcours ?? const [];
    if (parcours.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun parcours créé',
        message: 'Commencez par créer votre premier parcours.',
        icon: Icons.route_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.chargerDashboard,
      child: ListView.builder(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: parcours.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(bottom: YkSpacing.sm),
          child: _ParcoursCard(controller: controller, parcours: parcours[i]),
        ),
      ),
    );
  }
}

class _ParcoursCard extends StatelessWidget {
  const _ParcoursCard({required this.controller, required this.parcours});

  final AdminGeneralController controller;
  final ParcoursAdmin parcours;

  @override
  Widget build(BuildContext context) {
    final admin = parcours.enseignantAdmin;
    return YkCard(
      onTap: () => context.pushNamed(
        AppRoute.adminParcoursDetail,
        pathParameters: {'parcoursId': parcours.id.toString()},
        queryParameters: {'parcoursNom': parcours.nom, 'parcoursType': parcours.typeParcours},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parcours.nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text(
                      '${parcours.nbDepartements} départements · ${parcours.nbApprenants} apprenants',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              YkIconButton(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                variant: YkIconButtonVariant.ghost,
                onPressed: () => showModifierParcoursSheet(context, controller, parcours),
              ),
              YkIconButton(
                icon: admin == null ? Icons.person_add_outlined : Icons.swap_horiz,
                label: admin == null ? 'Nommer un admin' : "Changer l'admin",
                variant: YkIconButtonVariant.ghost,
                onPressed: () => showChangerAdminSheet(context, controller, parcours),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          YkBadge(
            variant: YkBadgeVariant.label,
            label: admin != null ? 'Admin : ${admin.nom}' : 'Aucun administrateur nommé',
            color: admin != null ? YkColors.accent(context) : YkColors.warning,
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(
                child: YkProgress(value: parcours.tauxMoyen / 100, shape: YkProgressShape.linear),
              ),
              SizedBox(width: YkSpacing.sm),
              Text(
                '${parcours.tauxMoyen.toStringAsFixed(0)}%',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.accent(context), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
