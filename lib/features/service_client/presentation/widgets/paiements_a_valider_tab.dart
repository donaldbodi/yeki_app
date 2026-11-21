import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/paiement_models.dart';

import '../service_client_controller.dart';
import 'demande_actions_sheet.dart';

/// Onglet « Paiements à valider » (P9.5) — `YkDataTable` (bascule
/// automatique en cartes sur petit écran), détail + valider/refuser via
/// [showDemandeActionsSheet].
class PaiementsAValiderTab extends StatelessWidget {
  const PaiementsAValiderTab({super.key, required this.controller});

  final ServiceClientController controller;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  Future<void> _ouvrirDetail(BuildContext context, DemandePaiementManuel demande) {
    return showDemandeActionsSheet(
      context,
      titre: 'Paiement #${demande.id}',
      details: [
        if (demande.apprenant != null) MapEntry('Apprenant', demande.apprenant!),
        MapEntry('Catégorie', demande.categorie),
        MapEntry('Montant déclaré', '${demande.montant} FCFA'),
        MapEntry('Opérateur', demande.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'),
        MapEntry('ID transaction', demande.idTransaction),
        MapEntry('Soumis le', _dateFmt.format(demande.dateCreation)),
      ],
      onValider: () => controller.validerPaiement(demande.id),
      onRefuser: (motif) => controller.refuserPaiement(demande.id, motif),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.chargementPaiements) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurPaiements) {
      return YkErrorState(
        message: 'Impossible de charger les paiements.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerPaiements,
      );
    }
    if (controller.paiements.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun paiement en attente',
        message: 'Les nouvelles demandes de paiement manuel apparaîtront ici.',
        icon: Icons.payments_outlined,
      );
    }

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkDataTable(
        columns: const [
          YkDataColumn(label: 'Apprenant'),
          YkDataColumn(label: 'Catégorie'),
          YkDataColumn(label: 'Montant', numeric: true),
          YkDataColumn(label: 'Opérateur'),
          YkDataColumn(label: 'Soumis le'),
        ],
        rows: [
          for (final d in controller.paiements)
            YkDataRowData(
              onTap: () => _ouvrirDetail(context, d),
              cells: [
                Text(d.apprenant ?? '—'),
                Text(d.categorie),
                Text('${d.montant} FCFA'),
                Text(d.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'),
                Text(_dateFmt.format(d.dateCreation)),
              ],
            ),
        ],
        cardBuilder: (context, i) {
          final d = controller.paiements[i];
          return YkCard(
            onTap: () => _ouvrirDetail(context, d),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        d.apprenant ?? '—',
                        style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ),
                    Text(
                      '${d.montant} FCFA',
                      style: YkTypography.h4(context).copyWith(color: YkColors.accent(context)),
                    ),
                  ],
                ),
                SizedBox(height: YkSpacing.xxs),
                Text(
                  '${d.categorie} — ${d.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'}',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                Text(
                  _dateFmt.format(d.dateCreation),
                  style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
