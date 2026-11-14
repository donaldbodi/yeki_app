import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/paiement_models.dart';

import '../service_client_controller.dart';
import 'demande_actions_sheet.dart';

/// Onglet « Retraits à valider » (P9.5) — même mécanique que Paiements,
/// avec le solde du bénéficiaire visible (exigence explicite du ticket) et
/// AUCUNE opération wallet à la validation (le solde a déjà été gelé à la
/// création — voir apps/paiement/views.py::ValiderRetraitView).
class RetraitsAValiderTab extends StatelessWidget {
  const RetraitsAValiderTab({super.key, required this.controller});

  final ServiceClientController controller;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  Future<void> _ouvrirDetail(BuildContext context, DemandeRetrait demande) {
    return showDemandeActionsSheet(
      context,
      titre: 'Retrait #${demande.id}',
      details: [
        if (demande.beneficiaire != null) MapEntry('Bénéficiaire', demande.beneficiaire!),
        if (demande.soldeBeneficiaire != null)
          MapEntry('Solde actuel du bénéficiaire', '${demande.soldeBeneficiaire} FCFA'),
        MapEntry('Montant brut', '${demande.montantBrut} FCFA'),
        MapEntry('Frais opérateur', '${demande.fraisOperateur} FCFA'),
        MapEntry('Montant net à envoyer', '${demande.montantNet} FCFA'),
        MapEntry('Opérateur', demande.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'),
        MapEntry('Numéro destination', demande.numeroDestination),
        MapEntry('Demandé le', _dateFmt.format(demande.dateCreation)),
      ],
      onValider: () => controller.validerRetrait(demande.id),
      onRefuser: (motif) => controller.refuserRetrait(demande.id, motif),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.chargementRetraits) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurRetraits) {
      return YkErrorState(
        message: 'Impossible de charger les retraits.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerRetraits,
      );
    }
    if (controller.retraits.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun retrait en attente',
        message: 'Les nouvelles demandes de retrait des cadres apparaîtront ici.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkDataTable(
        columns: const [
          YkDataColumn(label: 'Bénéficiaire'),
          YkDataColumn(label: 'Solde actuel', numeric: true),
          YkDataColumn(label: 'Montant net', numeric: true),
          YkDataColumn(label: 'Opérateur'),
          YkDataColumn(label: 'Demandé le'),
        ],
        rows: [
          for (final d in controller.retraits)
            YkDataRowData(
              onTap: () => _ouvrirDetail(context, d),
              cells: [
                Text(d.beneficiaire ?? '—'),
                Text('${d.soldeBeneficiaire ?? '—'} FCFA'),
                Text('${d.montantNet} FCFA'),
                Text(d.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'),
                Text(_dateFmt.format(d.dateCreation)),
              ],
            ),
        ],
        cardBuilder: (context, i) {
          final d = controller.retraits[i];
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
                        d.beneficiaire ?? '—',
                        style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ),
                    Text(
                      '${d.montantNet} FCFA',
                      style: YkTypography.h4(context).copyWith(color: YkColors.accent(context)),
                    ),
                  ],
                ),
                SizedBox(height: YkSpacing.xxs),
                Text(
                  'Solde actuel : ${d.soldeBeneficiaire ?? '—'} FCFA — '
                  '${d.operateur == 'orange_money' ? 'Orange Money' : 'MTN MoMo'}',
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
