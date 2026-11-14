import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';

import '../admin_general_controller.dart';

/// Onglet « Tous les cours » (P9.6) — `GET /cours/`, câblée pour la
/// première fois dans ce ticket (voir `admin_general_repository.dart`).
class TousCoursTab extends StatelessWidget {
  const TousCoursTab({super.key, required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementCours) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurCours) {
      return YkErrorState(
        message: 'Impossible de charger les cours.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerTousLesCours,
      );
    }
    if (controller.tousLesCours.isEmpty) {
      return const YkEmptyState(title: 'Aucun cours créé', message: '', icon: Icons.book_outlined);
    }
    return RefreshIndicator(
      onRefresh: controller.chargerTousLesCours,
      child: ListView.builder(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: controller.tousLesCours.length,
        itemBuilder: (_, i) {
          final c = controller.tousLesCours[i];
          Color color;
          try {
            color = Color(int.parse('FF${c.colorCode.replaceAll('#', '')}', radix: 16));
          } catch (_) {
            color = YkColors.accent(context);
          }
          return Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.sm),
            child: YkCard(
              onTap: () => context.pushNamed(
                AppRoute.coursDetailEnseignant,
                pathParameters: {'coursId': c.id.toString()},
                queryParameters: {'titre': c.titre, 'estEnseignantPrincipal': 'false'},
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(YkSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(YkRadius.sm),
                    ),
                    child: Icon(Icons.book, color: color, size: 20),
                  ),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.titre, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                        Text(
                          '${c.niveau} · ${c.nbApprenants} apprenants · ${c.nbLecons} leçons',
                          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: color),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
