import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import '../admin_general_controller.dart';

const _labelsCategorie = {
  'recharge': 'Recharge',
  'abonnement': 'Abonnement',
  'olympiade': 'Olympiade',
  'formation': 'Formation',
  'presentiel': 'Présentiel',
};

const _filtresCategorie = [
  YkDropdownItem<String>(value: '', label: 'Toutes catégories'),
  YkDropdownItem(value: 'recharge', label: 'Recharge'),
  YkDropdownItem(value: 'abonnement', label: 'Abonnement'),
  YkDropdownItem(value: 'olympiade', label: 'Olympiade'),
  YkDropdownItem(value: 'formation', label: 'Formation'),
  YkDropdownItem(value: 'presentiel', label: 'Présentiel'),
];

const _filtresStatut = [
  YkDropdownItem<String>(value: '', label: 'Tous statuts'),
  YkDropdownItem(value: 'succes', label: 'Succès'),
  YkDropdownItem(value: 'en_attente', label: 'En attente'),
  YkDropdownItem(value: 'echec', label: 'Échec'),
];

/// Onglet « Transactions » (P9.6, NOUVEAU) — tableau de bord financier +
/// liste filtrable des transactions. EXIGENCE EXPLICITE DU TICKET : les
/// deux répartitions (30/70 formations, 80/20 olympiades) restent
/// visibles séparément, ligne par ligne, jamais fondues ; le total dû aux
/// cadres est affiché comme un PASSIF, jamais additionné au total encaissé.
class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key, required this.controller});

  final AdminGeneralController controller;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _fmt = NumberFormat.decimalPattern('fr_FR');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        _FinancierSection(controller: controller, fmt: _fmt),
        SizedBox(height: YkSpacing.lg),
        _Filtres(controller: controller),
        SizedBox(height: YkSpacing.md),
        _ListeTransactions(controller: controller, dateFmt: _dateFmt),
      ],
    );
  }
}

class _FinancierSection extends StatelessWidget {
  const _FinancierSection({required this.controller, required this.fmt});

  final AdminGeneralController controller;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementFinancier) {
      return const YkSkeleton.grid(itemCount: 4);
    }
    if (controller.enErreurFinancier || controller.financier == null) {
      return YkErrorState(
        message: 'Impossible de charger le tableau de bord financier.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerFinancier,
      );
    }
    final f = controller.financier!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: YkBreakpoints.of(context) == YkBreakpoint.compact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: YkSpacing.sm,
          mainAxisSpacing: YkSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            YkStatCard(value: '${fmt.format(f.totalEncaisse)} F', label: 'Total encaissé', icon: Icons.account_balance_wallet),
            YkStatCard(value: '${fmt.format(f.soldeCompteIa)} F', label: 'Solde compte IA', icon: Icons.smart_toy_outlined),
            YkStatCard(
              value: '${fmt.format(f.soldeGeneralYekiCalcule)} F',
              label: 'Solde Yéki (calculé)',
              icon: Icons.calculate_outlined,
            ),
            YkStatCard(
              value: '${f.demandesEnAttentePaiement + f.demandesEnAttenteRetrait}',
              label: 'Demandes en attente',
              icon: Icons.hourglass_top_outlined,
            ),
          ],
        ),
        SizedBox(height: YkSpacing.sm),
        // Point comptable central du ticket : DETTE, jamais un revenu —
        // carte distincte, teinte d'alerte, jamais mêlée à "total encaissé".
        YkCard(
          accentColor: YkColors.warning,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: YkColors.warning),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total dû aux cadres (passif)',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                    Text(
                      '${fmt.format(f.totalDuAuxCadres)} FCFA',
                      style: YkTypography.h3(context).copyWith(color: YkColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: YkSpacing.sm),
        YkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ventilation par catégorie', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
              for (final entry in f.ventilationCategorie.entries)
                YkKeyValue(label: _labelsCategorie[entry.key] ?? entry.key, value: '${fmt.format(entry.value)} F'),
            ],
          ),
        ),
        if (f.ventilationDepartement.isNotEmpty) ...[
          SizedBox(height: YkSpacing.sm),
          YkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ventilation par département', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                for (final v in f.ventilationDepartement)
                  YkKeyValue(label: v.departementNom, value: '${fmt.format(v.total)} F'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Filtres extends StatelessWidget {
  const _Filtres({required this.controller});

  final AdminGeneralController controller;

  @override
  Widget build(BuildContext context) {
    final departements = controller.dashboard?.departements ?? const [];
    final itemsDepartements = <YkDropdownItem<int?>>[
      const YkDropdownItem(value: null, label: 'Tous départements'),
      for (final d in departements) YkDropdownItem(value: d.id, label: d.nom),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtres', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
        SizedBox(height: YkSpacing.xs),
        Row(
          children: [
            Expanded(
              child: YkDropdown<int?>(
                items: itemsDepartements,
                value: controller.filtreDepartementId,
                label: 'Département',
                onChanged: (v) {
                  controller.filtreDepartementId = v;
                  controller.chargerTransactions();
                },
              ),
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: YkDropdown<String>(
                items: _filtresCategorie,
                value: controller.filtreCategorie,
                label: 'Catégorie',
                onChanged: (v) {
                  controller.filtreCategorie = v ?? '';
                  controller.chargerTransactions();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: YkSpacing.sm),
        Row(
          children: [
            Expanded(
              child: YkDropdown<String>(
                items: _filtresStatut,
                value: controller.filtreStatut,
                label: 'Statut',
                onChanged: (v) {
                  controller.filtreStatut = v ?? '';
                  controller.chargerTransactions();
                },
              ),
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: YkDateTimePicker(
                mode: YkDateTimePickerMode.range,
                label: 'Période',
                rangeValue: controller.filtreDu.isNotEmpty && controller.filtreAu.isNotEmpty
                    ? DateTimeRange(start: DateTime.parse(controller.filtreDu), end: DateTime.parse(controller.filtreAu))
                    : null,
                onRangeChanged: (range) {
                  controller.filtreDu = DateFormat('yyyy-MM-dd').format(range.start);
                  controller.filtreAu = DateFormat('yyyy-MM-dd').format(range.end);
                  controller.chargerTransactions();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListeTransactions extends StatelessWidget {
  const _ListeTransactions({required this.controller, required this.dateFmt});

  final AdminGeneralController controller;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementTransactions) {
      return const YkSkeleton.list(itemCount: 5);
    }
    if (controller.enErreurTransactions) {
      return YkErrorState(
        message: 'Impossible de charger les transactions.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerTransactions,
      );
    }
    if (controller.transactions.isEmpty) {
      return const YkEmptyState(
        title: 'Aucune transaction',
        message: 'Aucune transaction ne correspond à ces filtres.',
        icon: Icons.receipt_long_outlined,
      );
    }
    return YkDataTable(
      columns: const [
        YkDataColumn(label: 'Date'),
        YkDataColumn(label: 'Apprenant'),
        YkDataColumn(label: 'Catégorie'),
        YkDataColumn(label: 'Département'),
        YkDataColumn(label: 'Montant brut', numeric: true),
        YkDataColumn(label: 'Part Yéki', numeric: true),
        YkDataColumn(label: 'Part tiers/bénéficiaire', numeric: true),
        YkDataColumn(label: 'Opérateur'),
        YkDataColumn(label: 'Statut'),
        YkDataColumn(label: 'Décideur'),
      ],
      rows: [
        for (final t in controller.transactions)
          YkDataRowData(
            cells: [
              Text(dateFmt.format(t.date)),
              Text(t.apprenant),
              Text(_labelsCategorie[t.categorie] ?? t.categorie),
              Text(t.departement ?? '—'),
              Text('${t.montantBrut} F'),
              Text('${t.partYeki} F'),
              Text(t.partTiersBeneficiaire > 0 ? '${t.partTiersBeneficiaire} F (${t.beneficiaire ?? '—'})' : '—'),
              Text(t.operateur),
              Text(t.statut),
              Text(t.decideur ?? '—'),
            ],
          ),
      ],
      cardBuilder: (context, i) {
        final t = controller.transactions[i];
        return YkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(t.apprenant, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                  ),
                  Text('${t.montantBrut} F', style: YkTypography.h4(context).copyWith(color: YkColors.accent(context))),
                ],
              ),
              Text(
                '${_labelsCategorie[t.categorie] ?? t.categorie} — ${t.departement ?? '—'}',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              Text(
                'Part Yéki : ${t.partYeki} F'
                '${t.partTiersBeneficiaire > 0 ? ' · Part tiers : ${t.partTiersBeneficiaire} F (${t.beneficiaire ?? '—'})' : ''}',
                style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              Text(
                '${dateFmt.format(t.date)} · ${t.operateur} · ${t.statut} · ${t.decideur ?? '—'}',
                style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
              ),
            ],
          ),
        );
      },
    );
  }
}
