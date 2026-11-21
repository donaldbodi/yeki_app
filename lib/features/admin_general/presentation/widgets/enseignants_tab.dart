import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/features/admin_general/data/admin_general_models.dart';

import '../admin_general_controller.dart';
import 'enseignant_edit_sheet.dart';

const _filtresType = [
  YkDropdownItem<String>(value: '', label: 'Tous les types'),
  YkDropdownItem(value: 'enseignant', label: 'Enseignant'),
  YkDropdownItem(value: 'enseignant_principal', label: 'Enseignant Principal'),
  YkDropdownItem(value: 'enseignant_cadre', label: 'Enseignant Cadre'),
  YkDropdownItem(value: 'enseignant_admin', label: 'Enseignant Admin'),
];

const _filtresStatut = [
  YkDropdownItem<bool?>(value: null, label: 'Tous les statuts'),
  YkDropdownItem(value: true, label: 'Autorisé'),
  YkDropdownItem(value: false, label: 'Non autorisé'),
];

/// Onglet « Enseignants » (P9.6) — recherche/filtres, édition du type de
/// rôle et du statut actif.
class EnseignantsTab extends StatelessWidget {
  const EnseignantsTab({super.key, required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(YkSpacing.md),
          child: Column(
            children: [
              YkSearchBar(
                hint: 'Rechercher un enseignant…',
                onQueryChanged: (v) {
                  controller.searchQuery = v;
                  controller.rechercherEnseignants();
                },
              ),
              SizedBox(height: YkSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: YkDropdown<String>(
                      items: _filtresType,
                      value: controller.filterUserType,
                      label: 'Type',
                      onChanged: (v) {
                        controller.filterUserType = v ?? '';
                        controller.rechercherEnseignants();
                      },
                    ),
                  ),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: YkDropdown<bool?>(
                      items: _filtresStatut,
                      value: controller.filterActif,
                      label: 'État',
                      onChanged: (v) {
                        controller.filterActif = v;
                        controller.rechercherEnseignants();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _Liste(controller: controller)),
      ],
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementEnseignants || controller.chargementDashboard) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurEnseignants) {
      return YkErrorState(
        message: 'Impossible de charger les enseignants.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.rechercherEnseignants,
      );
    }
    if (controller.enseignants.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun enseignant trouvé',
        message: "Essayez d'ajuster vos filtres de recherche.",
        icon: Icons.person_outline,
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
      itemCount: controller.enseignants.length,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: YkSpacing.sm),
        child: _EnseignantCard(controller: controller, enseignant: controller.enseignants[i]),
      ),
    );
  }
}

class _EnseignantCard extends StatelessWidget {
  const _EnseignantCard({required this.controller, required this.enseignant});

  final AdminGeneralController controller;
  final EnseignantAdmin enseignant;

  @override
  Widget build(BuildContext context) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              YkAvatar(imageUrl: enseignant.avatarUrl, fallbackText: enseignant.nom, size: YkAvatarSize.md),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enseignant.nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text(enseignant.email, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                    SizedBox(height: YkSpacing.xxs),
                    Row(
                      children: [
                        YkBadge(variant: YkBadgeVariant.label, label: enseignant.userType, color: YkColors.accent(context)),
                        SizedBox(width: YkSpacing.xs),
                        YkBadge(
                          variant: YkBadgeVariant.label,
                          label: enseignant.isActive ? 'Autorisé' : 'Non autorisé',
                          color: enseignant.isActive ? YkColors.success : YkColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              YkIconButton(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                variant: YkIconButtonVariant.ghost,
                onPressed: () => showModifierEnseignantSheet(context, controller, enseignant),
              ),
            ],
          ),
          if (enseignant.phone.isNotEmpty) ...[
            SizedBox(height: YkSpacing.xs),
            Text(
              enseignant.phone,
              style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ],
        ],
      ),
    );
  }
}
